package com.socadel.backend.entity;

import java.math.BigDecimal;

import jakarta.persistence.*;

/**
 * Fiche compteur electrique : reference, marque, modele, type, index initial
 * et localisation du point de livraison (latitude / longitude / quartier).
 */
@Entity
@Table(name = "compteur")
public class Compteur {

    public enum Statut { NON_INSPECTE, ACTIF, MAINTENANCE, PANNE, AUTRE }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 30)
    private String reference;

    @Column(length = 60)
    private String marque;

    @Column(length = 60)
    private String modele;

    @Column(nullable = false, length = 40)
    private String type = "Prépayé STS1";

    @Column(name = "index_initial", nullable = false, length = 20)
    private String indexInitial = "00000";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Statut statut = Statut.NON_INSPECTE;

    @Column(name = "statut_autre", length = 120)
    private String statutAutre;

    /** Adresse du point de livraison. */
    @Column(length = 160)
    private String quartier;

    @Column(nullable = false, precision = 10, scale = 6)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 10, scale = 6)
    private BigDecimal longitude;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "zone_id")
    private Zone zone;

    /** Technicien actuellement attribue a ce compteur. */
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "technicien_id")
    private Utilisateur technicien;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getReference() { return reference; }
    public void setReference(String reference) { this.reference = reference; }
    public String getMarque() { return marque; }
    public void setMarque(String marque) { this.marque = marque; }
    public String getModele() { return modele; }
    public void setModele(String modele) { this.modele = modele; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getIndexInitial() { return indexInitial; }
    public void setIndexInitial(String indexInitial) { this.indexInitial = indexInitial; }
    public Statut getStatut() { return statut; }
    public void setStatut(Statut statut) { this.statut = statut; }
    public String getStatutAutre() { return statutAutre; }
    public void setStatutAutre(String statutAutre) { this.statutAutre = statutAutre; }
    public String getQuartier() { return quartier; }
    public void setQuartier(String quartier) { this.quartier = quartier; }
    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }
    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }
    public Zone getZone() { return zone; }
    public void setZone(Zone zone) { this.zone = zone; }
    public Utilisateur getTechnicien() { return technicien; }
    public void setTechnicien(Utilisateur technicien) { this.technicien = technicien; }
}
