package com.openbag.account.service;

import com.openbag.account.dto.AddressDTO;
import com.openbag.account.entity.Address;
import com.openbag.account.entity.User;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.account.repository.AddressRepository;
import com.openbag.account.repository.UserRepository;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AddressRepository addressRepository;

    @Autowired
    private ModelMapper modelMapper;

    public User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
    }

    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado com ID: " + id));
    }

    /** Nome e telefone do usuário logado; o telefone continua único, como no cadastro */
    public User updateProfile(String fullName, String phoneNumber) {
        User currentUser = getCurrentUser();

        if (fullName != null && !fullName.isBlank()) {
            currentUser.setFullName(fullName.trim());
        }
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            String phone = phoneNumber.trim();
            if (!phone.equals(currentUser.getPhoneNumber()) && userRepository.existsByPhoneNumber(phone)) {
                throw new com.openbag.platform.web.exception.BadRequestException("Telefone já está em uso");
            }
            currentUser.setPhoneNumber(phone);
        }

        return userRepository.save(currentUser);
    }

    public List<AddressDTO> getUserAddresses() {
        User currentUser = getCurrentUser();
        return currentUser.getAddresses().stream()
                .map(address -> modelMapper.map(address, AddressDTO.class))
                .collect(Collectors.toList());
    }

    public AddressDTO addAddress(AddressDTO addressDTO) {
        User currentUser = getCurrentUser();
        
        Address address = modelMapper.map(addressDTO, Address.class);
        address.setUser(currentUser);
        
        Address savedAddress = addressRepository.save(address);
        return modelMapper.map(savedAddress, AddressDTO.class);
    }

    public AddressDTO updateAddress(Long addressId, AddressDTO addressDTO) {
        User currentUser = getCurrentUser();
        
        Address address = addressRepository.findByIdAndUserId(addressId, currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Endereço não encontrado"));
        
        modelMapper.map(addressDTO, address);
        address.setId(addressId);
        address.setUser(currentUser);
        
        Address updatedAddress = addressRepository.save(address);
        return modelMapper.map(updatedAddress, AddressDTO.class);
    }

    public void deleteAddress(Long addressId) {
        User currentUser = getCurrentUser();
        
        Address address = addressRepository.findByIdAndUserId(addressId, currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Endereço não encontrado"));
        
        addressRepository.delete(address);
    }

    public void deactivateUser() {
        User currentUser = getCurrentUser();
        currentUser.setActive(false);
        userRepository.save(currentUser);
    }
}
