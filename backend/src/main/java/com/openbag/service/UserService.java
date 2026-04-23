package com.openbag.service;

import com.openbag.dto.AddressDTO;
import com.openbag.entity.Address;
import com.openbag.entity.User;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.repository.AddressRepository;
import com.openbag.repository.UserRepository;
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

    public User updateUser(User userDetails) {
        User currentUser = getCurrentUser();
        
        if (userDetails.getFullName() != null) {
            currentUser.setFullName(userDetails.getFullName());
        }
        if (userDetails.getPhoneNumber() != null) {
            currentUser.setPhoneNumber(userDetails.getPhoneNumber());
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
