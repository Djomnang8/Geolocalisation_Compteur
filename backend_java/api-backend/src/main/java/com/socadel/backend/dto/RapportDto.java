package com.socadel.backend.dto;

import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;

import com.socadel.backend.entity.RapportInspection;

/** Rapport d'inspection expose par l'API. */
public record RapportDto(Long id, Long compteurId, String reference, String zone,
                         String technicienNom, String technicienMatricule, String date,
                         String etat, String etatAutre, List<String> anomalies,
                         String observations, boolean photo, String fichier, String gps,
                         String statut, String commentaireAdmin) {

    private static final DateTimeFormatter FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    public static RapportDto depuis(RapportInspection r) {
        List<String> anomalies = (r.getAnomalies() == null || r.getAnomalies().isBlank())
                ? List.of()
                : Arrays.stream(r.getAnomalies().split(";")).map(String::trim)
                        .filter(s -> !s.isEmpty()).toList();
        String gps = (r.getLatitude() == null || r.getLongitude() == null) ? "—"
                : r.getLatitude().stripTrailingZeros().toPlainString() + ", "
                + r.getLongitude().stripTrailingZeros().toPlainString();
        return new RapportDto(
                r.getId(), r.getCompteur().getId(), r.getCompteur().getReference(),
                r.getCompteur().getZone() == null ? null : r.getCompteur().getZone().getNom(),
                r.getTechnicien() == null ? "—" : r.getTechnicien().getNom(),
                r.getTechnicien() == null ? null : r.getTechnicien().getMatricule(),
                r.getDateIntervention().format(FORMAT),
                r.getEtat().name(), r.getEtatAutre(), anomalies, r.getObservations(),
                r.isPhoto(), r.getFichier(), gps, r.getStatut().name(), r.getCommentaireAdmin());
    }
}
