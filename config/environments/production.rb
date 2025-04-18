require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.year.to_i}, s-maxage=#{30.days.to_i}"
  }

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Melhorar compressão de CSS e JavaScript
  config.assets.css_compressor = :sass
  config.assets.js_compressor = :terser
  
  # Desativar a compilação de assets em tempo real para melhorar desempenho
  # e usar precompiled assets
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # "info" includes generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "debug")  # Temporariamente em debug para mais informações

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Configuração de cache otimizada para Heroku com fallback para memory_store
  if ENV["MEMCACHIER_SERVERS"]
    config.cache_store = :mem_cache_store,
                        ENV["MEMCACHIER_SERVERS"].split(","),
                        {
                          username: ENV["MEMCACHIER_USERNAME"],
                          password: ENV["MEMCACHIER_PASSWORD"],
                          failover: true,
                          socket_timeout: 1.5,
                          socket_failure_delay: 0.2,
                          down_retry_delay: 60,
                          pool_size: ENV.fetch("RAILS_MAX_THREADS") { 5 }
                        }
    config.action_controller.perform_caching = true
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.cache_store = :memory_store, { size: 64.megabytes }
    config.action_controller.perform_caching = true
  end

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter = :resque
  config.active_job.queue_name_prefix = "practice_pt_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = true

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # Configuração do Gmail para envio de emails em produção
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.smtp_settings = {
    address: 'smtp.gmail.com',
    port: 587,
    domain: 'exerciseapp.com.br',
    user_name: ENV['GMAIL_USERNAME'],
    password: ENV['GMAIL_PASSWORD'],
    authentication: :plain,
    enable_starttls_auto: true,
    open_timeout: 5,
    read_timeout: 5
  }
  
  # Adiciona cabeçalhos para evitar spam
  config.action_mailer.default_options = {
    from: 'Exercise App <no-reply@exerciseapp.com.br>',
    reply_to: 'suporte@exerciseapp.com.br',
    'X-MC-AutoText' => 'true',
    'X-Priority' => '3',
    'X-Mailer' => 'Exercise App Mailer',
    'Importance' => 'Normal',
    'Precedence' => 'Bulk'
  }
  
  # Host para os links nos emails
  config.action_mailer.default_url_options = { host: 'practicept.site', protocol: 'https' }
end
