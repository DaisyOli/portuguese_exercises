class PwaController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def manifest
    render json: {
      name:             "Practice-BR",
      short_name:       "Practice-BR",
      description:      t("pwa.description"),
      start_url:        "/student_dashboard",
      scope:            "/",
      display:          "standalone",
      orientation:      "portrait",
      background_color: "#F7F5F0",
      theme_color:      "#0F3826",
      lang:             I18n.locale.to_s,
      icons: [
        { src: "/icons/android-chrome-192x192.png", sizes: "192x192", type: "image/png" },
        { src: "/icons/android-chrome-512x512.png", sizes: "512x512", type: "image/png" },
        { src: "/icons/android-chrome-512x512.png", sizes: "512x512", type: "image/png", purpose: "maskable" }
      ]
    }, content_type: "application/manifest+json"
  end
end
