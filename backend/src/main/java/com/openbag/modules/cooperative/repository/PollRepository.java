package com.openbag.modules.cooperative.repository;

import com.openbag.enums.PollStatus;
import com.openbag.modules.cooperative.entity.Poll;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface PollRepository extends JpaRepository<Poll, Long> {

    List<Poll> findByOrganizationIdOrderByCreatedAtDesc(Long organizationId);

    List<Poll> findByOrganizationIdAndStatusInOrderByCreatedAtDesc(Long organizationId, Collection<PollStatus> statuses);

    Optional<Poll> findByIdAndOrganizationId(Long id, Long organizationId);
}
