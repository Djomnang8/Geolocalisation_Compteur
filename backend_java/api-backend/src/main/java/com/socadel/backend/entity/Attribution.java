package com.socadel.backend.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

/** Historique des affectations d'un compteur a un technicien. */
@Entity
@Table(name = "attribution")
public class Attribution {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "compteur_id")
    private Compteur compteur;

    @ManyToOne
    @JoinColumn(name = "technicien_id")
    private Utilisateur technicien;

    @Column(name = "date_attribution", nullable = false)
    private LocalDateTime dateAttribution = LocalDateTime.now();

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Compteur getCompteur() { return compteur; }
    public void setCompteur(Compteur compteur) { this.compteur = compteur; }
    public Utilisateur getTechnicien() { return technicien; }
    public void setTechnicien(Utilisateur technicien) { this.technicien = technicien; }
    public LocalDateTime getDateAttribution() { return dateAttribution; }
    public void setDateAttribution(LocalDateTime dateAttribution) { this.dateAttribution = dateAttribution; }
}
