class Rack::Attack
  # As chamadas legítimas vêm do servidor da landing (Vercel), então poucos IPs
  # concentram todo o tráfego real — por isso o limite por IP é generoso.
  throttle("trials/ip", limit: 30, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/api/v1/trials"
  end

  # Evita disparar vários convites para o mesmo endereço.
  throttle("trials/email", limit: 3, period: 1.hour) do |req|
    if req.post? && req.path == "/api/v1/trials"
      email = begin
        JSON.parse(req.body.read)["email"].to_s.strip.downcase
      rescue JSON::ParserError
        nil
      ensure
        req.body.rewind
      end
      email.presence
    end
  end

  self.throttled_responder = lambda do |_request|
    [429, { "Content-Type" => "application/json" }, [{ ok: false, error: "Muitas tentativas. Tente novamente mais tarde." }.to_json]]
  end
end
