package com.socadel.backend.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.socadel.backend.dto.UtilisateurDto;
import com.socadel.backend.dto.UtilisateurRequest;
import com.socadel.backend.entity.Utilisateur;
import com.socadel.backend.repository.CompteurRepository;
import com.socadel.backend.repository.UtilisateurRepository;

/**
 * Service metier de gestion des techniciens (CRUD administrateur) :
 * consulter, ajouter, modifier, rechercher, supprimer, et promouvoir
 * ou retirer le role administrateur.
 */
@Service
public class UtilisateurService {

    private final UtilisateurRepository utilisateurRepo;
    private final CompteurRepository compteurRepo;
    private final AuditService auditService;

    public UtilisateurService(UtilisateurRepository utilisateurRepo,
                              CompteurRepository compteurRepo, AuditService auditService) {
        this.utilisateurRepo = utilisateurRepo;
        this.compteurRepo = compteurRepo;
        this.auditService = auditService;
    }

    /** Liste des utilisateurs, avec recherche par nom ou matricule. */
    public List<UtilisateurDto> lister(String recherche) {
        String q = recherche == null ? "" : recherche.trim().toLowerCase();
        return utilisateurRepo.findAll().stream()
                .filter(u -> q.isEmpty()
                        || u.getNom().toLowerCase().contains(q)
                        || u.getMatricule().toLowerCase().contains(q))
                .map(this::versDto)
                .toList();
    }

    @Transactional
    public UtilisateurDto creer(UtilisateurRequest requete, String auteur) {
        // Regle de gestion : unicite du matricule
        if (utilisateurRepo.existsByMatriculeIgnoreCase(requete.matricule())) {
            throw new IllegalArgumentException("Ce matricule existe déjà.");
        }
        Utilisateur u = new Utilisateur();
        appliquer(u, requete);
        u.setMotDePasse(AuthService.hacher(
                requete.motDePasse() == null || requete.motDePasse().isBlank()
                        ? "1234" : requete.motDePasse()));
        utilisateurRepo.save(u);
        auditService.tracer(auteur, "Création technicien " + u.getMatricule());
        return versDto(u);
    }

    @Transactional
    public UtilisateurDto modifier(Long id, UtilisateurRequest requete, String auteur) {
        Utilisateur u = utilisateurRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable."));
        appliquer(u, requete);
        if (requete.motDePasse() != null && !requete.motDePasse().isBlank()) {
            u.setMotDePasse(AuthService.hacher(requete.motDePasse()));
        }
        utilisateurRepo.save(u);
        auditService.tracer(auteur, "Modification technicien " + u.getMatricule());
        return versDto(u);
    }

    @Transactional
    public void supprimer(Long id, String auteur) {
        Utilisateur u = utilisateurRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable."));
        // Les compteurs attribues repassent en "non attribue" (FK ON DELETE SET NULL)
        utilisateurRepo.delete(u);
        auditService.tracer(auteur, "Suppression technicien " + u.getMatricule());
    }

    /** Option "faire de lui un administrateur ou non" (cahier des charges). */
    @Transactional
    public UtilisateurDto basculerRole(Long id, String auteur) {
        Utilisateur u = utilisateurRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable."));
        u.setRole(u.getRole() == Utilisateur.Role.ADMIN
                ? Utilisateur.Role.TECHNICIEN : Utilisateur.Role.ADMIN);
        utilisateurRepo.save(u);
        auditService.tracer(auteur, "Changement de rôle " + u.getMatricule()
                + " → " + u.getRole().name());
        return versDto(u);
    }

    private void appliquer(Utilisateur u, UtilisateurRequest r) {
        if (r.nom() != null) u.setNom(r.nom().trim());
        if (r.matricule() != null) u.setMatricule(r.matricule().trim());
        if (r.role() != null) {
            u.setRole("ADMIN".equalsIgnoreCase(r.role())
                    ? Utilisateur.Role.ADMIN : Utilisateur.Role.TECHNICIEN);
        }
        if (r.zone() != null) u.setZone(r.zone());
        if (r.telephone() != null) u.setTelephone(r.telephone());
    }

    private UtilisateurDto versDto(Utilisateur u) {
        long compteurs = compteurRepo
                .findByTechnicienMatriculeIgnoreCaseOrderByReference(u.getMatricule()).size();
        return UtilisateurDto.depuis(u, compteurs);
    }
}
