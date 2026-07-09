class DatabaseConnectionRetry
  MAX_RETRIES = 2

  RETRYABLE = [
    ActiveRecord::DatabaseConnectionError,
    ActiveRecord::ConnectionTimeoutError,
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    retries = 0
    begin
      @app.call(env)
    rescue *RETRYABLE => e
      if retries < MAX_RETRIES
        retries += 1
        delay = retries * 0.5
        Rails.logger.warn "[DB Retry] #{e.class} — tentativa #{retries}/#{MAX_RETRIES}, aguardando #{delay}s"
        sleep delay
        # Não usar connection_pool.disconnect! aqui: derrubaria conexões
        # em uso por outras requisições. O Rails descarta sozinho a conexão
        # quebrada e abre uma nova no próximo checkout.
        env['rack.input'].rewind if env['rack.input'].respond_to?(:rewind)
        retry
      else
        Rails.logger.error "[DB Retry] Banco inacessível após #{MAX_RETRIES} tentativas: #{e.message}"
        raise
      end
    end
  end
end
