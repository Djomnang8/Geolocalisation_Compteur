package com.socadel.backend.service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.socadel.backend.dto.RapportDto;
import com.socadel.backend.entity.Compteur;
import com.socadel.backend.entity.Zone;
import com.socadel.backend.repository.CompteurRepository;
import com.socadel.backend.repository.RapportInspectionRepository;
import com.socadel.backend.repository.ZoneRepository;

/**
 * Service metier des statistiques : indicateurs (KPI) du tableau de bord
 * administrateur, repartition des compteurs par zone et rapports recents.
 */
@Service
public class StatistiqueService {

    private final CompteurRepository compteurRepo;
    private final ZoneRepository zoneRepo;
    private final RapportInspectionRepository rapportRepo;

    public StatistiqueService(CompteurRepository compteurRepo, ZoneRepository zoneRepo,
                              RapportInspectionRepository rapportRepo) {
        this.compteurRepo = compteurRepo;
        this.zoneRepo = zoneRepo;
        this.rapportRepo = rapportRepo;
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

        long max = Math.max(1, zones.stream()
                .mapToLong(z -> parZone(compteurs, z.getNom())).max().orElse(1));
        List<Map<String, Object>> zoneBars = zones.stream().map(z -> {
            long nb = parZone(compteurs, z.getNom());
            Map<String, Object> ligne = new LinkedHashMap<>();
            ligne.put("nom", z.getNom());
            ligne.put("couleur", z.getCouleur());
            ligne.put("compteurs", nb);
            ligne.put("pct", (int) Math.round(nb * 100.0 / max));
            ligne.put("couverture", z.getCouverture());
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

    private long parZone(List<Compteur> compteurs, String zone) {
        return compteurs.stream()
                .filter(c -> c.getZone() != null && zone.equals(c.getZone().getNom())).count();
    }
}
