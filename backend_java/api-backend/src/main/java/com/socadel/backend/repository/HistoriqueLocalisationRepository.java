package com.socadel.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.socadel.backend.entity.HistoriqueLocalisation;

public interface HistoriqueLocalisationRepository extends JpaRepository<HistoriqueLocalisation, Long> {

    List<HistoriqueLocalisation> findByCompteurIdOrderByDateCaptureDesc(Long compteurId);
}
