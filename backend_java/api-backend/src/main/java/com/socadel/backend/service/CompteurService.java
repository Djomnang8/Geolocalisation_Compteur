package com.socadel.backend.service;

import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.socadel.backend.dto.CompteurDto;
import com.socadel.backend.dto.CompteurRequest;
import com.socadel.backend.dto.HistoriqueDto;
import com.socadel.backend.entity.Attribution;
import com.socadel.backend.entity.Compteur;
import com.socadel.backend.entity.Utilisateur;
import com.socadel.backend.entity.Zone;
import com.socadel.backend.repository.AttributionRepository;
import com.socadel.backend.repository.CompteurRepository;
import com.socadel.backend.repository.HistoriqueLocalisationRepository;
import com.socadel.backend.repository.RapportInspectionRepository;
import com.socadel.backend.repository.UtilisateurRepository;
import com.socadel.backend.repository.ZoneRepository;

/**
 * Service metier des compteurs : CRUD des fiches, recherche par numero,
 * filtrage par statut, attribution aux techniciens et historique
 * de localisation / d'interventions.
 */
@Service
public class CompteurService {

    private static final DateTimeFormatter FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final CompteurRepository compteurRepo;
    private final ZoneRepository zoneRepo;
    private final UtilisateurRepository utilisateurRepo;
    private final AttributionRepository attributionRepo;
    private final RapportInspectionRepository rapportRepo;
    private final HistoriqueLocalisationRepository historiqueRepo;
    private final AuditService auditService;

    public CompteurService(CompteurRepository compteurRepo, ZoneRepository zoneRepo,
                           UtilisateurRepository utilisateurRepo, AttributionRepository attributionRepo,
                           RapportInspectionRepository rapportRepo,
                           HistoriqueLocalisationRepository historiqueRepo, AuditService auditService) {
        this.compteurRepo = compteurRepo;
        this.zoneRepo = zoneRepo;
        this.utilisateurRepo = utilisateurRepo;
        this.attributionRepo = attributionRepo;
        this.rapportRepo = rapportRepo;
        this.historiqueRepo = historiqueRepo;
        this.auditService = auditService;
    }

    /**
     * Liste des compteurs.
     *  - technicien : seuls les compteurs qui lui sont attribues (carte technicien) ;
     *  - administrateur : tous les compteurs de la ville de Douala (carte globale).
     * Recherche par numero / adresse et filtrage par statut.
     */
    public List<CompteurDto> lister(String matriculeTechnicien, String statut, String recherche) {
        List<Compteur> compteurs = (matriculeTechnicien == null || matriculeTechnicien.isBlank())
                ? compteurRepo.findAllByOrderByReference()
                : compteurRepo.findByTechnicienMatriculeIgnoreCaseOrderByReference(matriculeTechnicien);

        String q = recherche == null ? "" : recherche.trim().toLowerCase();
        return compteurs.stream()
                .filter(c -> statut == null || statut.isBlank() || "TOUS".equalsIgnoreCase(statut)
                        || c.getStatut().name().equalsIgnoreCase(statut))
                .filter(c -> q.isEmpty()
                        || c.getReference().toLowerCase().contains(q)
                        || (c.getQuartier() != null && c.getQuartier().toLowerCase().contains(q))
                        || (c.getZone() != null && c.getZone().getNom().toLowerCase().contains(q))
                        || (c.getTechnicien() != null && c.getTechnicien().getNom().toLowerCase().contains(q)))
                .map(CompteurDto::depuis)
                .toList();
    }

    public CompteurDto obtenir(Long id) {
        return CompteurDto.depuis(compteurRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Compteur introuvable.")));
    }

    @Transactional
    public CompteurDto creer(CompteurRequest requete, String auteur) {
        if (requete.reference() == null || requete.reference().isBlank()) {
            throw new IllegalArgumentException("La référence du compteur est requise.");
        }
        if (compteurRepo.findByReferenceIgnoreCase(requete.reference().trim()).isPresent()) {
            throw new IllegalArgumentException("Cette référence existe déjà.");
        }
        Compteur c = new Compteur();
        appliquer(c, requete);
        compteurRepo.save(c);
        if (c.getTechnicien() != null) {
            enregistrerAttribution(c, c.getTechnicien());
        }
        auditService.tracer(auteur, "Création compteur " + c.getReference());
        return CompteurDto.depuis(c);
    }

    @Transactional
    public CompteurDto modifier(Long id, CompteurRequest requete, String auteur) {
        Compteur c = compteurRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Compteur introuvable."));
        Utilisateur avant = c.getTechnicien();
        appliquer(c, requete);
        compteurRepo.save(c);
        if (c.getTechnicien() != avant) {
            enregistrerAttribution(c, c.getTechnicien());
            auditService.tracer(auteur, "Attribution " + c.getReference() + " → "
                    + (c.getTechnicien() == null ? "(non assigné)" : c.getTechnicien().getMatricule()));
        }
        auditService.tracer(auteur, "Modification compteur " + c.getReference());
        return CompteurDto.depuis(c);
    }

    @Transactional
    public void supprimer(Long id, String auteur) {
        Compteur c = compteurRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Compteur introuvable."));
        compteurRepo.delete(c);
        auditService.tracer(auteur, "Suppression compteur " + c.getReference());
    }

    /** Attribution d'un compteur a un technicien (ou retrait si matricule vide). */
    @Transactional
    public CompteurDto attribuer(Long id, String matricule, String auteur) {
        Compteur c = compteurRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Compteur introuvable."));
        Utilisateur technicien = (matricule == null || matricule.isBlank()) ? null
                : utilisateurRepo.findByMatriculeIgnoreCase(matricule)
                    .orElseThrow(() -> new IllegalArgumentException("Technicien introuvable."));
        c.setTechnicien(technicien);
        compteurRepo.save(c);
        enregistrerAttribution(c, technicien);
        auditService.tracer(auteur, "Attribution " + c.getReference() + " → "
                + (technicien == null ? "(non assigné)" : technicien.getMatricule()));
        return CompteurDto.depuis(c);
    }

    /** Historique des interventions et localisations d'un compteur. */
    public List<HistoriqueDto> historique(Long id) {
        List<HistoriqueDto> entrees = new ArrayList<>(rapportRepo
                .findByCompteurIdOrderByDateInterventionDesc(id).stream()
                .map(r -> new HistoriqueDto(
                        r.getDateIntervention().format(FORMAT),
                        "AUTRE".equals(r.getEtat().name()) && r.getEtatAutre() != null
                                ? "Autre — " + r.getEtatAutre() : libelle(r.getEtat().name()),
                        r.getObservations() == null ? "—" : r.getObservations(),
                        r.getTechnicien() == null ? "—" : r.getTechnicien().getNom(),
                        r.getLatitude() == null ? "—"
                                : r.getLatitude().stripTrailingZeros().toPlainString() + ", "
                                + r.getLongitude().stripTrailingZeros().toPlainString()))
                .toList());
        return entrees;
    }

    private void enregistrerAttribution(Compteur c, Utilisateur technicien) {
        Attribution a = new Attribution();
        a.setCompteur(c);
        a.setTechnicien(technicien);
        attributionRepo.save(a);
    }

    private void appliquer(Compteur c, CompteurRequest r) {
        if (r.reference() != null && !r.reference().isBlank()) c.setReference(r.reference().trim());
        if (r.marque() != null) c.setMarque(r.marque().trim());
        if (r.modele() != null) c.setModele(r.modele().trim());
        if (r.type() != null && !r.type().isBlank()) c.setType(r.type());
        if (r.indexInitial() != null && !r.indexInitial().isBlank()) c.setIndexInitial(r.indexInitial().trim());
        if (r.quartier() != null) c.setQuartier(r.quartier().trim());
        if (r.latitude() != null) c.setLatitude(BigDecimal.valueOf(r.latitude()));
        if (r.longitude() != null) c.setLongitude(BigDecimal.valueOf(r.longitude()));
        if (c.getLatitude() == null) c.setLatitude(BigDecimal.valueOf(4.0511));   // Douala par defaut
        if (c.getLongitude() == null) c.setLongitude(BigDecimal.valueOf(9.7679));
        if (r.zone() != null && !r.zone().isBlank()) {
            Zone zone = zoneRepo.findByNomIgnoreCase(r.zone())
                    .orElseThrow(() -> new IllegalArgumentException("Zone inconnue : " + r.zone()));
            c.setZone(zone);
        }
        if (r.technicienMatricule() != null) {
            c.setTechnicien(r.technicienMatricule().isBlank() ? null
                    : utilisateurRepo.findByMatriculeIgnoreCase(r.technicienMatricule())
                        .orElseThrow(() -> new IllegalArgumentException("Technicien introuvable.")));
        }
    }

    static String libelle(String statut) {
        return switch (statut) {
            case "ACTIF" -> "Actif";
            case "MAINTENANCE" -> "En maintenance";
            case "PANNE" -> "En panne";
            case "AUTRE" -> "Autre";
            default -> "Non inspecté";
        };
    }
}
