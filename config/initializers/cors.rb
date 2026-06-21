Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("ALLOWED_TRIAL_ORIGIN", "http://localhost:3000")

    resource "/api/v1/trials",
             headers: :any,
             methods: [:post, :options]
  end
end
