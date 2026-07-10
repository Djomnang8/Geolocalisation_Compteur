package com.socadel.backend.service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.socadel.backend.dto.RapportDto;
import com.socadel.backend.entity.Compteur;
import com.socadel.backend.entity.HistoriqueLocalisation;
import com.socadel.backend.entity.RapportInspection;
import com.socadel.backend.entity.Utilisateur;
import com.socadel.backend.entity.Zone;
import com.socadel.backend.repository.CompteurRepository;
import com.socadel.backend.repository.HistoriqueLocalisationRepository;
import com.socadel.backend.repository.RapportInspectionRepository;
import com.socadel.backend.repository.UtilisateurRepository;
import com.socadel.backend.repository.ZoneRepository;

/**
 * Service metier des statistiques : indicateurs (KPI) du tableau de bord
 * administrateur, repartition des compteurs par zone, zones de service et
 * suivi des deplacements des techniciens.
 */
@Service
public class StatistiqueService {

    private final CompteurRepository compteurRepo;
    private final ZoneRepository zoneRepo;
    private final RapportInspectionRepository rapportRepo;
    private final UtilisateurRepository utilisateurRepo;
    private final HistoriqueLocalisationRepository historiqueRepo;
    private final AuditService auditService;

    public StatistiqueService(CompteurRepository compteurRepo, ZoneRepository zoneRepo,
                              RapportInspectionRepository rapportRepo,
                              UtilisateurRepository utilisateurRepo,
                              HistoriqueLocalisationRepository historiqueRepo,
                              AuditService auditService) {
        this.compteurRepo = compteurRepo;
        this.zoneRepo = zoneRepo;
        this.rapportRepo = rapportRepo;
        this.utilisateurRepo = utilisateurRepo;
        this.historiqueRepo = historiqueRepo;
        this.auditService = auditService;
    }

    /** KPI du tableau de bord administrateur. */
    public Map<String, Object> tableauDeBord() {
        List<Compteur> compteurs = compteurRepo.findAll();
        List<Zone> zones = zoneRepo.findAll();

        long total = compteurs.size();
        long pannes = compteurs.stream()
                .filter(c -> c.getStatut() == Compteur.Statut.PANNE).count();
        long interventions = rapportRepo.count();
        int tauxPanne = total == 0 ? 0 : (int) Math.round(pannes * 100.0 / total);
        int couverture = zones.isEmpty() ? 0
                : (int) Math.round(zones.stream().mapToInt(Zone::getCouverture).average().orElse(0));

        List<RapportInspection> rapports = rapportRepo.findAll();
        long max = Math.max(1, zones.stream()
                .mapToLong(z -> parZone(compteurs, z.getNom())).max().orElse(1));
        List<Map<String, Object>> zoneBars = zones.stream().map(z -> {
            long nb = parZone(compteurs, z.getNom());
            long pannesZone = compteurs.stream()
                    .filter(c -> c.getZone() != null && z.getNom().equals(c.getZone().getNom()))
                    .filter(c -> c.getStatut() == Compteur.Statut.PANNE).count();
            long interventionsZone = rapports.stream()
                    .filter(r -> r.getCompteur().getZone() != null
                            && z.getNom().equals(r.getCompteur().getZone().getNom())).count();
            Map<String, Object> ligne = new LinkedHashMap<>();
            ligne.put("id", z.getId());
            ligne.put("nom", z.getNom());
            ligne.put("couleur", z.getCouleur());
            ligne.put("compteurs", nb);
            ligne.put("pct", (int) Math.round(nb * 100.0 / max));
            ligne.put("couverture", z.getCouverture());
            ligne.put("interventions", interventionsZone);
            ligne.put("pannes", pannesZone);
            ligne.put("tauxPanne", nb == 0 ? 0 : (int) Math.round(pannesZone * 100.0 / nb));
            return ligne;
        }).toList();

        List<RapportDto> recents = rapportRepo.findAllByOrderByDateInterventionDesc().stream()
                .limit(3).map(RapportDto::depuis).toList();

        Map<String, Object> reponse = new LinkedHashMap<>();
        reponse.put("totalCompteurs", total);
        reponse.put("interventions", interventions);
        reponse.put("tauxPanne", tauxPanne);
        reponse.put("couverture", couverture);
        reponse.put("zoneBars", zoneBars);
        reponse.put("rapportsRecents", recents);
        return reponse;
    }

    /** Liste des zones de service (pour les formulaires et la carte). */
    public List<Map<String, Object>> zones() {
        return zoneRepo.findAll().stream().map(z -> {
            Map<String, Object> ligne = new LinkedHashMap<>();
            ligne.put("id", z.getId());
            ligne.put("nom", z.getNom());
            ligne.put("couleur", z.getCouleur());
            ligne.put("couverture", z.getCouverture());
            return ligne;
        }).toList();
    }

    /** Creation d'une zone de service (bouton "Tracer une nouvelle zone"). */
    @Transactional
    public Map<String, Object> creerZone(String nom, String couleur, Integer couverture, String auteur) {
        if (nom == null || nom.isBlank()) {
            throw new IllegalArgumentException("Renseignez le nom de la zone.");
        }
        if (zoneRepo.findAll().stream().anyMatch(z -> z.getNom().equalsIgnoreCase(nom.trim()))) {
            throw new IllegalArgumentException("Cette zone existe déjà.");
        }
        Zone z = new Zone();
        z.setNom(nom.trim());
        z.setCouleur(couleur == null || couleur.isBlank() ? "#15357a" : couleur.trim());
        z.setCouverture(couverture == null ? 0 : Math.max(0, Math.min(100, couverture)));
        zoneRepo.save(z);
        auditService.tracer(auteur, "Création de la zone « " + z.getNom() + " »");
        return ligneZone(z);
    }

    /** Modification d'une zone de service (nom, couleur, couverture). */
    @Transactional
    public Map<String, Object> modifierZone(Long id, String nom, String couleur,
                                            Integer couverture, String auteur) {
        Zone z = zoneRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Zone introuvable."));
        if (nom != null && !nom.isBlank()) {
            // Unicite : aucune autre zone ne doit deja porter ce nom
            zoneRepo.findByNomIgnoreCase(nom.trim())
                    .filter(autre -> !autre.getId().equals(id))
                    .ifPresent(autre -> {
                        throw new IllegalArgumentException("Une autre zone porte déjà ce nom.");
                    });
            z.setNom(nom.trim());
        }
        if (couleur != null && !couleur.isBlank()) {
            z.setCouleur(couleur.trim());
        }
        if (couverture != null) {
            z.setCouverture(Math.max(0, Math.min(100, couverture)));
        }
        zoneRepo.save(z);
        auditService.tracer(auteur, "Modification de la zone « " + z.getNom() + " »");
        return ligneZone(z);
    }

    /**
     * Suppression d'une zone de service. Les compteurs qui y etaient rattaches
     * ne sont pas supprimes : ils repassent simplement « sans zone ».
     */
    @Transactional
    public void supprimerZone(Long id, String auteur) {
        Zone z = zoneRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Zone introuvable."));
        List<Compteur> rattaches = compteurRepo.findAll().stream()
                .filter(c -> c.getZone() != null && c.getZone().getId().equals(id))
                .toList();
        for (Compteur c : rattaches) {
            c.setZone(null);
            compteurRepo.save(c);
        }
        zoneRepo.delete(z);
        auditService.tracer(auteur, "Suppression de la zone « " + z.getNom() + " » ("
                + rattaches.size() + " compteur(s) détaché(s))");
    }

    /** Mise en forme d'une zone pour l'API. */
    private Map<String, Object> ligneZone(Zone z) {
        Map<String, Object> ligne = new LinkedHashMap<>();
        ligne.put("id", z.getId());
        ligne.put("nom", z.getNom());
        ligne.put("couleur", z.getCouleur());
        ligne.put("couverture", z.getCouverture());
        return ligne;
    }

    /**
     * Suivi des deplacements des techniciens (page administrateur "Suivi") :
     * pour chaque technicien, derniere position connue, temps de trajet et
     * distance estimes a partir des captures GPS, compteurs inspectes / attribues.
     */
    public List<Map<String, Object>> suivi() {
        DateTimeFormatter heure = DateTimeFormatter.ofPattern("HH:mm");
        List<HistoriqueLocalisation> captures = historiqueRepo.findAll();
        return utilisateurRepo.findAll().stream()
                .filter(u -> u.getRole() == Utilisateur.Role.TECHNICIEN)
                .map(t -> {
                    List<HistoriqueLocalisation> siennes = captures.stream()
                            .filter(h -> h.getTechnicien() != null
                                    && h.getTechnicien().getId().equals(t.getId()))
                            .sorted(Comparator.comparing(HistoriqueLocalisation::getDateCapture))
                            .toList();
                    long attribues = compteurRepo
                            .findByTechnicienMatriculeIgnoreCaseOrderByReference(t.getMatricule())
                            .size();

                    Map<String, Object> ligne = new LinkedHashMap<>();
                    ligne.put("nom", t.getNom());
                    ligne.put("matricule", t.getMatricule());
                    ligne.put("total", attribues);

                    if (siennes.isEmpty()) {
                        ligne.put("dernierePosition", "Aucune capture GPS");
                        ligne.put("tempsTrajet", "—");
                        ligne.put("distanceKm", 0.0);
                        ligne.put("inspectes", 0);
                        return ligne;
                    }
                    // Journee d'activite la plus recente du technicien
                    HistoriqueLocalisation derniere = siennes.get(siennes.size() - 1);
                    LocalDate jour = derniere.getDateCapture().toLocalDate();
                    List<HistoriqueLocalisation> duJour = siennes.stream()
                            .filter(h -> h.getDateCapture().toLocalDate().equals(jour))
                            .toList();

                    double km = 0;
                    for (int i = 1; i < duJour.size(); i++) {
                        km += haversineKm(
                                duJour.get(i - 1).getLatitude().doubleValue(),
                                duJour.get(i - 1).getLongitude().doubleValue(),
                                duJour.get(i).getLatitude().doubleValue(),
                                duJour.get(i).getLongitude().doubleValue());
                    }
                    // Estimation du temps de trajet en ville (~20 km/h de moyenne)
                    int minutes = (int) Math.round(km / 20.0 * 60);
                    String temps = minutes < 60 ? minutes + " min"
                            : (minutes / 60) + "h " + String.format("%02d", minutes % 60);

                    long inspectes = rapportRepo.findAll().stream()
                            .filter(r -> r.getTechnicien() != null
                                    && r.getTechnicien().getId().equals(t.getId())
                                    && r.getDateIntervention().toLocalDate().equals(jour))
                            .count();

                    String quartier = derniere.getCompteur().getQuartier();
                    ligne.put("dernierePosition",
                            (quartier == null ? derniere.getCompteur().getReference() : quartier)
                                    + " · " + derniere.getDateCapture().format(heure));
                    ligne.put("tempsTrajet", km == 0 ? "—" : temps);
                    ligne.put("distanceKm", Math.round(km * 10.0) / 10.0);
                    ligne.put("inspectes", inspectes);
                    return ligne;
                })
                .toList();
    }

    /** Distance a vol d'oiseau entre deux points GPS (formule de haversine). */
    private static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        double rayonTerre = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return 2 * rayonTerre * Math.asin(Math.sqrt(a));
    }

    private long parZone(List<Compteur> compteurs, String zone) {
        return compteurs.stream()
                .filter(c -> c.getZone() != null && zone.equals(c.getZone().getNom())).count();
    }
}
