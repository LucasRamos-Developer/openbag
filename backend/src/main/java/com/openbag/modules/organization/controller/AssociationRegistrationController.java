package com.openbag.modules.organization.controller;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.openbag.exception.BadRequestException;
import com.openbag.modules.organization.dto.AssociationDTO;
import com.openbag.modules.organization.dto.AssociationOnboardingRequest;
import com.openbag.modules.organization.dto.DeliveryPersonRegisterRequest;
import com.openbag.modules.organization.dto.MemberDTO;
import com.openbag.modules.organization.service.AssociationService;
import com.openbag.modules.organization.service.MembershipService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Valid;
import jakarta.validation.Validator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Set;

@RestController
@RequestMapping("/auth/register")
@Tag(name = "Association Registration", description = "Cadastro público de associações/cooperativas e entregadores")
public class AssociationRegistrationController {

    @Autowired
    private AssociationService associationService;

    @Autowired
    private MembershipService membershipService;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private Validator validator;

    @PostMapping(value = "/association", consumes = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Cadastro de associação (JSON)",
            description = "Cadastra a associação/cooperativa e seu gestor. A associação fica aguardando aprovação de um ADMIN")
    public ResponseEntity<AssociationDTO> registerAssociationJson(@Valid @RequestBody AssociationOnboardingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(associationService.register(request, null));
    }

    @PostMapping(value = "/association", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Cadastro de associação (com logo)",
            description = "Parte 'data' com o JSON do cadastro e parte opcional 'logo' com a imagem")
    public ResponseEntity<AssociationDTO> registerAssociationMultipart(
            @RequestPart("data") String dataJson,
            @RequestPart(value = "logo", required = false) MultipartFile logo) {
        AssociationOnboardingRequest request = parseAndValidate(dataJson);
        return ResponseEntity.status(HttpStatus.CREATED).body(associationService.register(request, logo));
    }

    @PostMapping("/delivery-person")
    @Operation(summary = "Cadastro de entregador",
            description = "Cria a conta do entregador vinculada a uma associação. Com código de convite o entregador " +
                    "já entra ativo; informando apenas a associação, fica aguardando aprovação do gestor")
    public ResponseEntity<MemberDTO> registerDeliveryPerson(@Valid @RequestBody DeliveryPersonRegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(membershipService.registerDeliveryPerson(request));
    }

    private AssociationOnboardingRequest parseAndValidate(String dataJson) {
        AssociationOnboardingRequest request;
        try {
            request = objectMapper.readValue(dataJson, AssociationOnboardingRequest.class);
        } catch (JsonProcessingException e) {
            throw new BadRequestException("JSON da parte 'data' inválido");
        }
        // O JSON da parte multipart não passa pelo @Valid, então valida manualmente
        Set<ConstraintViolation<AssociationOnboardingRequest>> violations = validator.validate(request);
        if (!violations.isEmpty()) {
            throw new ConstraintViolationException(violations);
        }
        return request;
    }
}
