package com.openbag.modules.delivery.service;

import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.delivery.dto.StaffCourierDTO;
import com.openbag.modules.delivery.dto.StaffCourierRequest;
import com.openbag.modules.delivery.entity.StaffCourier;
import com.openbag.modules.delivery.repository.StaffCourierRepository;
import com.openbag.modules.restaurant.repository.RestaurantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Equipe própria do restaurante (entregadores sem o app)
 */
@Service
@Transactional
public class StaffCourierService {

    @Autowired
    private StaffCourierRepository staffRepository;

    @Autowired
    private RestaurantRepository restaurantRepository;

    @Transactional(readOnly = true)
    public List<StaffCourierDTO> list(Long restaurantId) {
        return staffRepository.findByRestaurantIdAndActiveTrueOrderByNameAsc(restaurantId).stream()
                .map(StaffCourierDTO::from)
                .toList();
    }

    public StaffCourierDTO create(Long restaurantId, StaffCourierRequest request) {
        StaffCourier staff = new StaffCourier();
        staff.setRestaurant(restaurantRepository.findById(restaurantId)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante não encontrado")));
        apply(staff, request);
        return StaffCourierDTO.from(staffRepository.save(staff));
    }

    public StaffCourierDTO update(Long restaurantId, Long staffId, StaffCourierRequest request) {
        StaffCourier staff = find(restaurantId, staffId);
        apply(staff, request);
        return StaffCourierDTO.from(staffRepository.save(staff));
    }

    public void deactivate(Long restaurantId, Long staffId) {
        StaffCourier staff = find(restaurantId, staffId);
        staff.setActive(false);
        staffRepository.save(staff);
    }

    private StaffCourier find(Long restaurantId, Long staffId) {
        return staffRepository.findByIdAndRestaurantId(staffId, restaurantId)
                .filter(StaffCourier::isActive)
                .orElseThrow(() -> new ResourceNotFoundException("Entregador da equipe não encontrado"));
    }

    private static void apply(StaffCourier staff, StaffCourierRequest request) {
        staff.setName(request.name().trim());
        staff.setPhone(request.phone() == null || request.phone().isBlank() ? null : request.phone().trim());
        staff.setFeePerDelivery(request.feePerDelivery());
    }
}
