package com.socadel.backend.entity;

import jakarta.persistence.*;

/**
 * Utilisateur de l'application : technicien ou administrateur (RBACL).
 * Authentification unifiee : nom + matricule unique + mot de passe (hache SHA-256).
 */
@Entity
@Table(name = "utilisateur")
public class Utilisateur {

    public enum Role { TECHNICIEN, ADMIN }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String nom;

    @Column(nullable = false, unique = true, length = 30)
    private String matricule;

    /** Hachage SHA-256 du mot de passe (jamais stocke en clair). */
    @Column(name = "mot_de_passe", nullable = false, length = 64)
    private String motDePasse;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role = Role.TECHNICIEN;

    @Column(length = 80)
    private String zone;

    @Column(length = 30)
    private String telephone;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getMatricule() { return matricule; }
    public void setMatricule(String matricule) { this.matricule = matricule; }
    public String getMotDePasse() { return motDePasse; }
    public void setMotDePasse(String motDePasse) { this.motDePasse = motDePasse; }
    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }
    public String getZone() { return zone; }
    public void setZone(String zone) { this.zone = zone; }
    public String getTelephone() { return telephone; }
    public void setTelephone(String telephone) { this.telephone = telephone; }
}
