# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

# CDN das dependências para garantir disponibilidade em produção
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js", preload: true
pin "@popperjs/core", to: "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/umd/popper.min.js", preload: true
pin "@rails/ujs", to: "https://cdn.jsdelivr.net/npm/@rails/ujs@7.1.2/app/assets/javascripts/rails-ujs.js", preload: true
pin "jquery", to: "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", preload: true
pin "jquery_ujs", to: "https://cdn.jsdelivr.net/npm/jquery-ujs@1.2.3/src/rails.min.js", preload: true
pin "sortablejs", to: "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js", preload: true
