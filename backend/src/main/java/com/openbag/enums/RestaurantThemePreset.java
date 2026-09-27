package com.openbag.enums;

/**
 * Temas prontos da página pública do restaurante. As cores completas vivem no frontend
 * (AppThemePreset); aqui fica só o necessário para o servidor (cor principal e se é escuro).
 */
public enum RestaurantThemePreset {
    FRESH_GREEN("Fresh Green", "#00A878", false),
    SUNSET_ORANGE("Sunset Orange", "#F4511E", false),
    BERRY_PINK("Berry Pink", "#D83A73", false),
    OCEAN_BLUE("Ocean Blue", "#008CC2", false),
    GRAPE_PURPLE("Grape Purple", "#7B3FC6", false),
    MIDNIGHT_GREEN("Midnight Green", "#19B887", true),
    MIDNIGHT_BLUE("Midnight Blue", "#3BA7D6", true),
    GRAPHITE("Graphite", "#E05A47", true);

    public static final RestaurantThemePreset DEFAULT = FRESH_GREEN;

    private final String displayName;
    private final String primaryHex;
    private final boolean dark;

    RestaurantThemePreset(String displayName, String primaryHex, boolean dark) {
        this.displayName = displayName;
        this.primaryHex = primaryHex;
        this.dark = dark;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getPrimaryHex() {
        return primaryHex;
    }

    public boolean isDark() {
        return dark;
    }
}
