package com.openbag.modules.shared.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * Controller para health check da aplicação
 */
@RestController
@RequestMapping("/api/health")
@Tag(name = "Health", description = "API de health check")
public class HealthController {

    @GetMapping
    @Operation(summary = "Health check", description = "Verifica se a aplicação está funcionando")
    public ResponseEntity<Map<String, String>> healthCheck() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        return ResponseEntity.ok(response);
    }
}
