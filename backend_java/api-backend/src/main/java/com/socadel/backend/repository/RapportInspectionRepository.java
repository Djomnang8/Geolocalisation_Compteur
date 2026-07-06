package com.socadel.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.socadel.backend.entity.RapportInspection;

public interface RapportInspectionRepository extends JpaRepository<RapportInspection, Long> {

    List<RapportInspection> findAllByOrderByDateInterventionDesc();

    List<RapportInspection> findByTechnicienMatriculeIgnoreCaseOrderByDateInterventionDesc(String matricule);

    List<RapportInspection> findByCompteurIdOrderByDateInterventionDesc(Long compteurId);

    long countByStatut(RapportInspection.Statut statut);
}
