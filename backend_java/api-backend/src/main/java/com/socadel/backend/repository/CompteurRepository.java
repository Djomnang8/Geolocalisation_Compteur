package com.socadel.backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.socadel.backend.entity.Compteur;

public interface CompteurRepository extends JpaRepository<Compteur, Long> {

    Optional<Compteur> findByReferenceIgnoreCase(String reference);

    List<Compteur> findByTechnicienMatriculeIgnoreCaseOrderByReference(String matricule);

    List<Compteur> findAllByOrderByReference();
}
