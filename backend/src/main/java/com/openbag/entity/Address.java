package com.openbag.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "addresses")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Address {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 200)
    private String street;

    @NotBlank
    @Size(max = 10)
    private String number;

    @Size(max = 100)
    private String complement;

    @NotBlank
    @Size(max = 100)
    private String neighborhood;

    @NotBlank
    @Size(max = 100)
    private String city;

    @NotBlank
    @Size(max = 50)
    private String state;

    @NotBlank
    @Size(max = 10)
    @Column(name = "zip_code")
    private String zipCode;

    @Column(precision = 10, scale = 8)
    private Double latitude;

    @Column(precision = 11, scale = 8)
    private Double longitude;

    @Column(name = "is_default")
    private boolean isDefault = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    public Address(String street, String number, String neighborhood, String city, String state, String zipCode) {
        this.street = street;
        this.number = number;
        this.neighborhood = neighborhood;
        this.city = city;
        this.state = state;
        this.zipCode = zipCode;
    }

    public String getFullAddress() {
        StringBuilder fullAddress = new StringBuilder();
        fullAddress.append(street).append(", ").append(number);
        if (complement != null && !complement.isEmpty()) {
            fullAddress.append(", ").append(complement);
        }
        fullAddress.append(", ").append(neighborhood)
                .append(", ").append(city)
                .append(" - ").append(state)
                .append(", ").append(zipCode);
        return fullAddress.toString();
    }
}
