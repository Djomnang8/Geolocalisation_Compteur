package com.socadel.backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.socadel.backend.entity.Utilisateur;

public interface UtilisateurRepository extends JpaRepository<Utilisateur, Long> {

    Optional<Utilisateur> findByMatriculeIgnoreCase(String matricule);

    boolean existsByMatriculeIgnoreCase(String matricule);
}
