package com.socadel.backend.entity;

import jakarta.persistence.*;

/** Zone de service geographique de l'agence de Koumassi (Douala). */
@Entity
@Table(name = "zone")
public class Zone {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 80)
    private String nom;

    @Column(nullable = false, length = 10)
    private String couleur = "#15357a";

    /** Taux de couverture de la zone (en %). */
    @Column(nullable = false)
    private int couverture;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getCouleur() { return couleur; }
    public void setCouleur(String couleur) { this.couleur = couleur; }
    public int getCouverture() { return couverture; }
    public void setCouverture(int couverture) { this.couverture = couverture; }
}
