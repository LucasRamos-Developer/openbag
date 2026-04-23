package com.openbag.modules.product.service;

import com.openbag.modules.product.dto.CustomizationGroupRequest;
import com.openbag.modules.product.dto.CustomizationOptionRequest;
import com.openbag.modules.product.entity.CustomizationGroup;
import com.openbag.modules.product.entity.CustomizationOption;
import com.openbag.modules.product.entity.Product;
import com.openbag.modules.product.repository.CustomizationGroupRepository;
import com.openbag.modules.product.repository.CustomizationOptionRepository;
import com.openbag.modules.product.repository.ProductRepository;
import com.openbag.modules.shared.exception.ResourceNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class CustomizationService {

    @Autowired
    private CustomizationGroupRepository customizationGroupRepository;

    @Autowired
    private CustomizationOptionRepository customizationOptionRepository;

    @Autowired
    private ProductRepository productRepository;

    /**
     * Listar todos os grupos de customização de um produto
     */
    public List<CustomizationGroup> getCustomizationGroupsByProductId(Long productId) {
        return customizationGroupRepository.findByProductIdOrderByIdAsc(productId);
    }

    /**
     * Criar grupo de customização para um produto
     */
    @Transactional
    public CustomizationGroup createCustomizationGroup(CustomizationGroupRequest request) {
        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Produto não encontrado"));

        CustomizationGroup group = new CustomizationGroup();
        group.setName(request.getName());
        group.setRequired(request.isRequired());
        group.setMinSelections(request.getMinSelections());
        group.setMaxSelections(request.getMaxSelections());
        group.setProduct(product);

        CustomizationGroup savedGroup = customizationGroupRepository.save(group);

        // Criar opções associadas
        if (request.getOptions() != null && !request.getOptions().isEmpty()) {
            for (CustomizationOptionRequest optionReq : request.getOptions()) {
                CustomizationOption option = new CustomizationOption();
                option.setName(optionReq.getName());
                option.setPriceModifier(optionReq.getPriceModifier());
                option.setAvailable(optionReq.isAvailable());
                option.setDisplayOrder(optionReq.getDisplayOrder());
                option.setCustomizationGroup(savedGroup);
                
                customizationOptionRepository.save(option);
            }
        }

        return customizationGroupRepository.findById(savedGroup.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Grupo criado mas não encontrado"));
    }

    /**
     * Atualizar grupo de customização
     */
    @Transactional
    public CustomizationGroup updateCustomizationGroup(Long id, CustomizationGroupRequest request) {
        CustomizationGroup group = customizationGroupRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Grupo de customização não encontrado"));

        if (request.getName() != null) {
            group.setName(request.getName());
        }
        group.setRequired(request.isRequired());
        if (request.getMinSelections() != null) {
            group.setMinSelections(request.getMinSelections());
        }
        if (request.getMaxSelections() != null) {
            group.setMaxSelections(request.getMaxSelections());
        }

        return customizationGroupRepository.save(group);
    }

    /**
     * Deletar grupo de customização
     */
    @Transactional
    public void deleteCustomizationGroup(Long id) {
        CustomizationGroup group = customizationGroupRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Grupo de customização não encontrado"));
        customizationGroupRepository.delete(group);
    }

    /**
     * Adicionar opção a um grupo
     */
    @Transactional
    public CustomizationOption addOptionToGroup(Long groupId, CustomizationOptionRequest request) {
        CustomizationGroup group = customizationGroupRepository.findById(groupId)
                .orElseThrow(() -> new ResourceNotFoundException("Grupo de customização não encontrado"));

        CustomizationOption option = new CustomizationOption();
        option.setName(request.getName());
        option.setPriceModifier(request.getPriceModifier());
        option.setAvailable(request.isAvailable());
        option.setDisplayOrder(request.getDisplayOrder());
        option.setCustomizationGroup(group);

        return customizationOptionRepository.save(option);
    }

    /**
     * Atualizar opção de customização
     */
    @Transactional
    public CustomizationOption updateCustomizationOption(Long optionId, CustomizationOptionRequest request) {
        CustomizationOption option = customizationOptionRepository.findById(optionId)
                .orElseThrow(() -> new ResourceNotFoundException("Opção de customização não encontrada"));

        if (request.getName() != null) {
            option.setName(request.getName());
        }
        if (request.getPriceModifier() != null) {
            option.setPriceModifier(request.getPriceModifier());
        }
        option.setAvailable(request.isAvailable());
        if (request.getDisplayOrder() != null) {
            option.setDisplayOrder(request.getDisplayOrder());
        }

        return customizationOptionRepository.save(option);
    }

    /**
     * Deletar opção de customização
     */
    @Transactional
    public void deleteCustomizationOption(Long optionId) {
        CustomizationOption option = customizationOptionRepository.findById(optionId)
                .orElseThrow(() -> new ResourceNotFoundException("Opção de customização não encontrada"));
        customizationOptionRepository.delete(option);
    }

    /**
     * Listar opções de um grupo
     */
    public List<CustomizationOption> getOptionsByGroupId(Long groupId) {
        return customizationOptionRepository.findByCustomizationGroupIdOrderByDisplayOrderAsc(groupId);
    }
}
