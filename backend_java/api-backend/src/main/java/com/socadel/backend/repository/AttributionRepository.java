package com.socadel.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.socadel.backend.entity.Attribution;

public interface AttributionRepository extends JpaRepository<Attribution, Long> {
}
