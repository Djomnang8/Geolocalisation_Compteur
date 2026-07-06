package com.socadel.backend.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

/** Journal d'audit : tracabilite des actions sensibles (norme ISO 27001). */
@Entity
@Table(name = "journal_audit")
public class JournalAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String utilisateur;

    @Column(nullable = false, length = 255)
    private String action;

    @Column(name = "date_action", nullable = false)
    private LocalDateTime dateAction = LocalDateTime.now();

    public JournalAudit() { }

    public JournalAudit(String utilisateur, String action) {
        this.utilisateur = utilisateur;
        this.action = action;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUtilisateur() { return utilisateur; }
    public void setUtilisateur(String utilisateur) { this.utilisateur = utilisateur; }
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }
    public LocalDateTime getDateAction() { return dateAction; }
    public void setDateAction(LocalDateTime dateAction) { this.dateAction = dateAction; }
}
