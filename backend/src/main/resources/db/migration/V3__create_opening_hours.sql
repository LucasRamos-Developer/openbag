-- Create opening_hours table for restaurant operating hours
CREATE TABLE opening_hours (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id BIGINT NOT NULL,
    label VARCHAR(50),
    weekday INT NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    observation VARCHAR(255),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
);

-- Create index for better query performance
CREATE INDEX idx_opening_hours_restaurant ON opening_hours(restaurant_id);
