package com.socadel.backend.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.*;

/** Historique des positions GPS enregistrees lors des visites d'un compteur. */
@Entity
@Table(name = "historique_localisation")
public class HistoriqueLocalisation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    @JoinColumn(name = "compteur_id")
    private Compteur compteur;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "technicien_id")
    private Utilisateur technicien;

    @Column(nullable = false, precision = 10, scale = 6)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 10, scale = 6)
    private BigDecimal longitude;

    @Column(name = "date_capture", nullable = false)
    private LocalDateTime dateCapture = LocalDateTime.now();

    @Column(length = 255)
    private String note;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Compteur getCompteur() { return compteur; }
    public void setCompteur(Compteur compteur) { this.compteur = compteur; }
    public Utilisateur getTechnicien() { return technicien; }
    public void setTechnicien(Utilisateur technicien) { this.technicien = technicien; }
    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }
    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }
    public LocalDateTime getDateCapture() { return dateCapture; }
    public void setDateCapture(LocalDateTime dateCapture) { this.dateCapture = dateCapture; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
