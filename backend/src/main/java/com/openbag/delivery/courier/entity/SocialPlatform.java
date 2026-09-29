package com.openbag.delivery.courier.entity;

public enum SocialPlatform {
    INSTAGRAM("Instagram"),
    FACEBOOK("Facebook"),
    TIKTOK("TikTok"),
    WHATSAPP("WhatsApp"),
    YOUTUBE("YouTube"),
    WEBSITE("Site"),
    OTHER("Outro");

    private final String displayName;

    SocialPlatform(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
