package com.openbag.association.community.repository;

import com.openbag.association.community.entity.PollVote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface PollVoteRepository extends JpaRepository<PollVote, Long> {

    /** Votos por opção: [pollId, optionId, quantidade] */
    @Query("SELECT v.poll.id, v.option.id, COUNT(v) FROM PollVote v WHERE v.poll.id IN :pollIds "
            + "GROUP BY v.poll.id, v.option.id")
    List<Object[]> countByOption(@Param("pollIds") Collection<Long> pollIds);

    /** Em que opção o cooperado votou em cada enquete: [pollId, optionId] */
    @Query("SELECT v.poll.id, v.option.id FROM PollVote v WHERE v.membership.id = :membershipId AND v.poll.id IN :pollIds")
    List<Object[]> choicesOf(@Param("membershipId") Long membershipId, @Param("pollIds") Collection<Long> pollIds);

    Optional<PollVote> findByPollIdAndMembershipId(Long pollId, Long membershipId);
}
