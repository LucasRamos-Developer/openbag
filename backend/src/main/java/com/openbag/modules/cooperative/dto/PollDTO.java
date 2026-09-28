package com.openbag.modules.cooperative.dto;

import com.openbag.enums.PollStatus;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Enquete com o resultado. Para o cooperado, as contagens só aparecem depois que ele vota ou quando ela encerra
 * ({@code showResults}); {@code myOptionId} é o voto dele. O voto é secreto: ninguém vê quem votou em quê.
 */
public record PollDTO(Long id, String question, String description, PollStatus status, LocalDateTime openedAt,
                      LocalDateTime closesAt, LocalDateTime closedAt, List<Option> options, long totalVotes,
                      long eligibleVoters, boolean showResults, Long myOptionId) {

    public record Option(Long id, String label, Long votes) {
    }
}
