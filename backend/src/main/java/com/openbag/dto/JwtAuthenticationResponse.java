package com.openbag.dto;

import com.openbag.entity.User;
import com.openbag.enums.UserType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class JwtAuthenticationResponse {

    private String accessToken;
    private String tokenType = "Bearer";
    private UserDto user;

    public JwtAuthenticationResponse(String accessToken, UserDto user) {
        this.accessToken = accessToken;
        this.user = user;
    }

    @Data
    @NoArgsConstructor
    public static class UserDto {
        private Long id;
        private String fullName;
        private String email;
        private String phoneNumber;
        private UserType userType;
        private boolean isActive;

        public UserDto(User user) {
            this.id = user.getId();
            this.fullName = user.getFullName();
            this.email = user.getEmail();
            this.phoneNumber = user.getPhoneNumber();
            this.userType = user.getUserType();
            this.isActive = user.isActive();
        }
    }
}
