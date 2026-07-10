require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = false

  # Configuração do Devise Mailer
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  
  # Emails capturados pelo LetterOpenerWeb em desenvolvimento — acesse em /letter_opener
  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.perform_deliveries = true

  # Para testar com Gmail real, comente as duas linhas acima e descomente:
  # config.action_mailer.delivery_method = :smtp
  # config.action_mailer.smtp_settings = {
  #   address: 'smtp.gmail.com', port: 587, domain: 'gmail.com',
  #   user_name: ENV['GMAIL_USERNAME'], password: ENV['GMAIL_PASSWORD'],
  #   authentication: :plain, enable_starttls_auto: true
  # }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Mesma fila da produção (GoodJob), rodando dentro do servidor de desenvolvimento
  config.active_job.queue_adapter = :good_job
  config.good_job = { execution_mode: :async }

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  config.after_initialize do
    Bullet.enable       = true
    Bullet.alert        = false # popup atrapalhava o uso; avisos seguem no rodapé e no log
    Bullet.rails_logger = true
    Bullet.add_footer   = true

    # Activity cover/badge helpers check all 3 attachment types regardless of which are present
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Activity", association: :image_file_attachment)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Activity", association: :video_file_attachment)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Activity", association: :audio_file_attachment)
    # Active Storage blobs are used by rails_blob_path but Bullet can't track that
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :blob)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "ActiveStorage::Blob", association: :variant_records)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "ActiveStorage::Blob", association: :preview_image_attachment)
    # sentence_words_count counter cache é usado em vez de carregar a associação
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "SentenceOrdering", association: :sentence_words)
    # activity_ratings: includes necessário para evitar N+1 quando há avaliações
    # Bullet não consegue prever que o badge condicional vai usar a associação
    Bullet.add_safelist(type: :counter_cache,        class_name: "Activity", association: :activity_ratings)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Activity", association: :activity_ratings)
    # admin/drafts usa .size nas 4 associações para contar exercícios;
    # com rascunhos sem exercícios o Bullet acusa eager loading "não usado"
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Activity", association: :questions)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Activity", association: :sentence_orderings)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Activity", association: :paragraph_orderings)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Activity", association: :column_matchings)
  end
end
