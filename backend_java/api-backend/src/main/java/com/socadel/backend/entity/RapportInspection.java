package com.socadel.backend.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.*;

/**
 * Rapport d'inspection envoye par le technicien a l'administrateur :
 * etat du compteur, anomalies, observations, photo, position GPS capturee,
 * horodatage automatique, puis avis (validation / rejet) de l'administrateur.
 */
@Entity
@Table(name = "rapport_inspection")
public class RapportInspection {

    public enum Etat { ACTIF, MAINTENANCE, PANNE, AUTRE }
    public enum Statut { EN_ATTENTE, VALIDE, REJETE }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    @JoinColumn(name = "compteur_id")
    private Compteur compteur;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "technicien_id")
    private Utilisateur technicien;

    /** Horodatage automatique de l'intervention. */
    @Column(name = "date_intervention", nullable = false)
    private LocalDateTime dateIntervention = LocalDateTime.now();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Etat etat;

    @Column(name = "etat_autre", length = 120)
    private String etatAutre;

    /** Anomalies constatees, separees par des points-virgules. */
    @Column(columnDefinition = "TEXT")
    private String anomalies;

    @Column(columnDefinition = "TEXT")
    private String observations;

    /** Photo jointe comme preuve de visite. */
    @Column(nullable = false)
    private boolean photo;

    /** Octets de la photo (JPEG), consultables par l'administrateur. */
    @Lob
    @Column(name = "photo_donnees", columnDefinition = "LONGBLOB")
    private byte[] photoDonnees;

    @Column(length = 190)
    private String fichier;

    /** Octets du fichier joint (PDF, DOCX...), consultables par l'administrateur. */
    @Lob
    @Column(name = "fichier_donnees", columnDefinition = "LONGBLOB")
    private byte[] fichierDonnees;

    /** Position GPS precise capturee lors de la visite. */
    @Column(precision = 10, scale = 6)
    private BigDecimal latitude;

    @Column(precision = 10, scale = 6)
    private BigDecimal longitude;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Statut statut = Statut.EN_ATTENTE;

    @Column(name = "commentaire_admin", columnDefinition = "TEXT")
    private String commentaireAdmin;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Compteur getCompteur() { return compteur; }
    public void setCompteur(Compteur compteur) { this.compteur = compteur; }
    public Utilisateur getTechnicien() { return technicien; }
    public void setTechnicien(Utilisateur technicien) { this.technicien = technicien; }
    public LocalDateTime getDateIntervention() { return dateIntervention; }
    public void setDateIntervention(LocalDateTime dateIntervention) { this.dateIntervention = dateIntervention; }
    public Etat getEtat() { return etat; }
    public void setEtat(Etat etat) { this.etat = etat; }
    public String getEtatAutre() { return etatAutre; }
    public void setEtatAutre(String etatAutre) { this.etatAutre = etatAutre; }
    public String getAnomalies() { return anomalies; }
    public void setAnomalies(String anomalies) { this.anomalies = anomalies; }
    public String getObservations() { return observations; }
    public void setObservations(String observations) { this.observations = observations; }
    public boolean isPhoto() { return photo; }
    public void setPhoto(boolean photo) { this.photo = photo; }
    public byte[] getPhotoDonnees() { return photoDonnees; }
    public void setPhotoDonnees(byte[] photoDonnees) { this.photoDonnees = photoDonnees; }
    public String getFichier() { return fichier; }
    public void setFichier(String fichier) { this.fichier = fichier; }
    public byte[] getFichierDonnees() { return fichierDonnees; }
    public void setFichierDonnees(byte[] fichierDonnees) { this.fichierDonnees = fichierDonnees; }
    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }
    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }
    public Statut getStatut() { return statut; }
    public void setStatut(Statut statut) { this.statut = statut; }
    public String getCommentaireAdmin() { return commentaireAdmin; }
    public void setCommentaireAdmin(String commentaireAdmin) { this.commentaireAdmin = commentaireAdmin; }
}
