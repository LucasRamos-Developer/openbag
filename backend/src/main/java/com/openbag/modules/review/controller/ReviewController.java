package com.openbag.modules.review.controller;

import com.openbag.annotation.IsRestaurantOwner;
import com.openbag.modules.review.dto.*;
import com.openbag.modules.review.service.ReviewService;
import com.openbag.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Avaliações: o cliente avalia o pedido entregue e a loja acompanha e responde
 */
@RestController
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Reviews", description = "Avaliação da loja e do entregador depois da entrega")
public class ReviewController {

    @Autowired
    private ReviewService reviewService;

    @Autowired
    private UserService userService;

    @PostMapping("/orders/{id}/review")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Avaliar pedido",
            description = "Só o cliente do pedido, depois da entrega e em até " + ReviewService.REVIEW_WINDOW_DAYS
                    + " dias. A nota do entregador só vale para entregador do app.")
    public ResponseEntity<OrderReviewDTO> create(@PathVariable Long id, @Valid @RequestBody CreateReviewRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(reviewService.create(userService.getCurrentUser(), id, request));
    }

    @GetMapping("/restaurants/{restaurantId}/reviews")
    @IsRestaurantOwner
    @Operation(summary = "Avaliações da loja", description = "Mais recentes primeiro, sem a nota do entregador")
    public ResponseEntity<Page<RestaurantReviewDTO>> list(@PathVariable Long restaurantId,
                                                          @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(reviewService.listForRestaurant(restaurantId, pageable));
    }

    @GetMapping("/restaurants/{restaurantId}/reviews/summary")
    @IsRestaurantOwner
    @Operation(summary = "Resumo das avaliações", description = "Média, total e quantidade por nota")
    public ResponseEntity<ReviewSummaryDTO> summary(@PathVariable Long restaurantId) {
        return ResponseEntity.ok(reviewService.summary(restaurantId));
    }

    @PostMapping("/restaurants/{restaurantId}/reviews/{reviewId}/reply")
    @IsRestaurantOwner
    @Operation(summary = "Responder avaliação", description = "A resposta aparece para o cliente; enviar de novo substitui")
    public ResponseEntity<RestaurantReviewDTO> reply(@PathVariable Long restaurantId, @PathVariable Long reviewId,
                                                     @Valid @RequestBody ReplyRequest request) {
        return ResponseEntity.ok(reviewService.reply(restaurantId, reviewId, request));
    }
}
