package com.openbag.delivery.courier.controller;

import com.openbag.delivery.courier.dto.CourierPublicDTO;
import com.openbag.delivery.courier.service.CourierProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/public/couriers")
@Tag(name = "Public Couriers", description = "Perfil público do entregador (QR code da placa de verificação)")
public class PublicCourierController {

    @Autowired
    private CourierProfileService profileService;

    @GetMapping("/{slug}")
    @Operation(summary = "Perfil público do entregador")
    public ResponseEntity<CourierPublicDTO> getPublicProfile(@PathVariable String slug) {
        return ResponseEntity.ok(profileService.getPublicProfile(slug));
    }
}
