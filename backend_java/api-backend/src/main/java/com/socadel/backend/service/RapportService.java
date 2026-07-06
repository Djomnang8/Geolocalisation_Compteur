package com.socadel.backend.service;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.socadel.backend.dto.AvisRequest;
import com.socadel.backend.dto.RapportDto;
import com.socadel.backend.dto.RapportRequest;
import com.socadel.backend.entity.Compteur;
import com.socadel.backend.entity.HistoriqueLocalisation;
import com.socadel.backend.entity.RapportInspection;
import com.socadel.backend.entity.Utilisateur;
import com.socadel.backend.repository.CompteurRepository;
import com.socadel.backend.repository.HistoriqueLocalisationRepository;
import com.socadel.backend.repository.RapportInspectionRepository;
import com.socadel.backend.repository.UtilisateurRepository;

/**
 * Service metier des rapports d'inspection.
 *
 * Envoi par le technicien (diagramme de sequence "Remplir et envoyer un
 * rapport d'inspection") : la transaction enregistre le rapport, met a jour
 * le statut du compteur, capture la position GPS dans l'historique de
 * localisation et trace l'action dans le journal d'audit.
 *
 * Traitement par l'administrateur (diagramme "Consultation et validation
 * d'un rapport") : avis Valide / Rejete + commentaire transmis au technicien.
 */
@Service
public class RapportService {

    private final RapportInspectionRepository rapportRepo;
    private final CompteurRepository compteurRepo;
    private final UtilisateurRepository utilisateurRepo;
    private final HistoriqueLocalisationRepository historiqueRepo;
    private final AuditService auditService;

    public RapportService(RapportInspectionRepository rapportRepo, CompteurRepository compteurRepo,
                          UtilisateurRepository utilisateurRepo,
                          HistoriqueLocalisationRepository historiqueRepo, AuditService auditService) {
        this.rapportRepo = rapportRepo;
        this.compteurRepo = compteurRepo;
        this.utilisateurRepo = utilisateurRepo;
        this.historiqueRepo = historiqueRepo;
        this.auditService = auditService;
    }

    /** Liste des rapports (tous pour l'admin, filtres par technicien et/ou statut). */
    public List<RapportDto> lister(String matricule, String statut) {
        List<RapportInspection> rapports = (matricule == null || matricule.isBlank())
                ? rapportRepo.findAllByOrderByDateInterventionDesc()
                : rapportRepo.findByTechnicienMatriculeIgnoreCaseOrderByDateInterventionDesc(matricule);
        return rapports.stream()
                .filter(r -> statut == null || statut.isBlank() || "TOUS".equalsIgnoreCase(statut)
                        || r.getStatut().name().equalsIgnoreCase(statut))
                .map(RapportDto::depuis)
                .toList();
    }

    public RapportDto obtenir(Long id) {
        return RapportDto.depuis(rapportRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Rapport introuvable.")));
    }

    /** Envoi d'un rapport d'inspection par le technicien. */
    @Transactional
    public RapportDto envoyer(RapportRequest requete) {
        // Regles de gestion (validation des donnees)
        if (requete.etat() == null || requete.etat().isBlank()) {
            throw new IllegalArgumentException("Sélectionnez l'état du compteur.");
        }
        if ("AUTRE".equalsIgnoreCase(requete.etat())
                && (requete.etatAutre() == null || requete.etatAutre().isBlank())) {
            throw new IllegalArgumentException("Précisez l'état du compteur (champ Autre).");
        }
        if (requete.observations() == null || requete.observations().isBlank()) {
            throw new IllegalArgumentException("Renseignez les observations.");
        }
        Compteur compteur = compteurRepo.findById(requete.compteurId())
                .orElseThrow(() -> new IllegalArgumentException("Compteur introuvable."));
        Utilisateur technicien = utilisateurRepo.findByMatriculeIgnoreCase(requete.matricule())
                .orElseThrow(() -> new IllegalArgumentException("Technicien introuvable."));

        RapportInspection r = new RapportInspection();
        r.setCompteur(compteur);
        r.setTechnicien(technicien);
        r.setEtat(RapportInspection.Etat.valueOf(requete.etat().toUpperCase()));
        r.setEtatAutre(requete.etatAutre());
        r.setAnomalies(requete.anomalies());
        r.setObservations(requete.observations());
        r.setPhoto(Boolean.TRUE.equals(requete.photo()));
        r.setFichier(requete.fichier());
        if (requete.latitude() != null && requete.longitude() != null) {
            r.setLatitude(BigDecimal.valueOf(requete.latitude()));
            r.setLongitude(BigDecimal.valueOf(requete.longitude()));
        }
        rapportRepo.save(r);

        // L'etat defini dans le rapport devient visible sur la carte
        compteur.setStatut(Compteur.Statut.valueOf(requete.etat().toUpperCase()));
        compteur.setStatutAutre("AUTRE".equalsIgnoreCase(requete.etat()) ? requete.etatAutre() : null);
        compteurRepo.save(compteur);

        // Capture de la position GPS dans l'historique de localisation
        if (r.getLatitude() != null) {
            HistoriqueLocalisation h = new HistoriqueLocalisation();
            h.setCompteur(compteur);
            h.setTechnicien(technicien);
            h.setLatitude(r.getLatitude());
            h.setLongitude(r.getLongitude());
            h.setNote("Capture lors de l'inspection");
            historiqueRepo.save(h);
            auditService.tracer(technicien.getNom(), "Capture GPS · " + compteur.getReference());
        }
        auditService.tracer(technicien.getNom(),
                "Envoi rapport d'inspection · " + compteur.getReference());
        return RapportDto.depuis(r);
    }

    /** Avis de l'administrateur : validation ou rejet + commentaire. */
    @Transactional
    public RapportDto donnerAvis(Long id, AvisRequest avis) {
        RapportInspection r = rapportRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Rapport introuvable."));
        boolean valide = "VALIDE".equalsIgnoreCase(avis.statut());
        r.setStatut(valide ? RapportInspection.Statut.VALIDE : RapportInspection.Statut.REJETE);
        if (avis.commentaire() != null) {
            r.setCommentaireAdmin(avis.commentaire());
        }
        rapportRepo.save(r);

        String auteur = avis.matriculeAdmin() == null ? "Administrateur"
                : utilisateurRepo.findByMatriculeIgnoreCase(avis.matriculeAdmin())
                    .map(Utilisateur::getNom).orElse("Administrateur");
        auditService.tracer(auteur, "Avis « " + (valide ? "Validé" : "Rejeté")
                + " » sur le rapport R" + r.getId());
        return RapportDto.depuis(r);
    }
}
