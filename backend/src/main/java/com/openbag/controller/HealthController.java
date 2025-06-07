package com.openbag.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class HealthController {

    @GetMapping
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = Map.of(
            "status", "UP",
            "timestamp", LocalDateTime.now(),
            "service", "Open Food API",
            "version", "1.0.0"
        );
        
        return ResponseEntity.ok(response);
    }
}
