package com.socadel.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.socadel.backend.entity.JournalAudit;

public interface JournalAuditRepository extends JpaRepository<JournalAudit, Long> {

    List<JournalAudit> findAllByOrderByDateActionDesc();
}
