package com.socadel.backend.service;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.socadel.backend.entity.JournalAudit;
import com.socadel.backend.repository.JournalAuditRepository;

/**
 * Service metier du journal d'audit : trace toutes les actions sensibles
 * (connexions, envois de rapports, validations, CRUD) - norme ISO 27001.
 */
@Service
public class AuditService {

    private static final DateTimeFormatter FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final JournalAuditRepository journalRepo;

    public AuditService(JournalAuditRepository journalRepo) {
        this.journalRepo = journalRepo;
    }

    /** Enregistre une action sensible dans le journal d'audit. */
    public void tracer(String utilisateur, String action) {
        journalRepo.save(new JournalAudit(utilisateur, action));
    }

    /** Journal complet, du plus recent au plus ancien. */
    public List<Map<String, String>> journal() {
        return journalRepo.findAllByOrderByDateActionDesc().stream()
                .map(a -> Map.of(
                        "date", a.getDateAction().format(FORMAT),
                        "utilisateur", a.getUtilisateur(),
                        "action", a.getAction()))
                .toList();
    }
}
