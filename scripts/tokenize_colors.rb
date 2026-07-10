# Substitui hex hard-coded por var(--token) — design system da franquia Practice.
# Rode da raiz do app: ruby scripts/tokenize_colors.rb [--apply]
# Sem --apply é dry-run: só relata o que faria e os hex não mapeados.
# Ao adotar em outro app da franquia, ajuste o mapa hex→token abaixo
# para a paleta local (ver docs/DESIGN_SYSTEM.md).

APPLY = ARGV.include?('--apply')
ROOT  = Dir.pwd

# hex (maiúsculo, 6 dígitos) => token
MAP6 = {
  # neutros
  '#1C1917' => 'ink', '#44403C' => 'ink', '#3D3A36' => 'ink', '#333333' => 'ink',
  '#5C5853' => 'ink-soft',
  '#9C9892' => 'ink-faint', '#9C9690' => 'ink-faint', '#C4BFB8' => 'ink-faint',
  '#B5B0AA' => 'ink-faint', '#C0BBB3' => 'ink-faint',
  '#F7F5F0' => 'paper', '#F7F5F2' => 'paper', '#F5F3F0' => 'paper', '#FAFAF8' => 'paper',
  '#EDEAE4' => 'paper-2', '#EAE7E2' => 'paper-2', '#ECEAE5' => 'paper-2',
  '#E8E5E0' => 'paper-2', '#E8E5DF' => 'paper-2', '#E8E4DC' => 'paper-2',
  '#EAEAEA' => 'paper-2', '#E5E1D8' => 'paper-2',
  '#FFFFFF' => 'surface',
  '#FAFAF9' => 'surface-2',
  '#DDD9D2' => 'line', '#D1D5DB' => 'line', '#E5E2DE' => 'line',
  '#F0EDE8' => 'line-soft',
  '#F3F4F6' => 'neutral-tint',
  '#374151' => 'neutral-ink',
  # marca
  '#0F3826' => 'brand-deep',
  '#1A6B4A' => 'brand', '#2A6B4A' => 'brand',
  '#2A9B6F' => 'brand-bright',
  '#6EBD96' => 'brand-soft', '#A7DFC0' => 'brand-soft', '#A7D9C0' => 'brand-soft',
  '#D1EAD9' => 'brand-tint-2', '#D4EDE3' => 'brand-tint-2',
  '#E8F5EE' => 'brand-tint',
  '#F0FAF5' => 'brand-mist', '#F0FAF4' => 'brand-mist', '#F0F9F4' => 'brand-mist',
  '#F7FDF9' => 'brand-mist', '#EBF7F2' => 'brand-mist', '#F0F7F4' => 'brand-mist',
  # ação (dourado)
  '#C9952A' => 'action', '#B8841E' => 'action-hover', '#E6B65C' => 'action-bright',
  '#E8C97A' => 'action-border',
  '#F5D478' => 'action-soft', '#F5E0A0' => 'action-soft',
  '#FBF3E0' => 'action-tint', '#FFF8E7' => 'action-tint', '#FFFBF0' => 'action-tint',
  '#FFFDF5' => 'action-tint',
  '#7C4A00' => 'action-ink', '#A06000' => 'action-ink', '#9C7A30' => 'action-ink',
  '#7C5500' => 'action-ink',
  # success
  '#15803D' => 'success', '#16A34A' => 'success',
  '#166534' => 'success-deep', '#065F46' => 'success-deep',
  '#BBF7D0' => 'success-border', '#86EFAC' => 'success-border', '#A7F3D0' => 'success-border',
  '#DCFCE7' => 'success-tint', '#ECFDF5' => 'success-tint', '#F0FDF4' => 'success-tint',
  # error
  '#B91C1C' => 'error', '#C0392B' => 'error', '#BE123C' => 'error',
  '#991B1B' => 'error-deep', '#7F1D1D' => 'error-deep',
  '#FECACA' => 'error-border', '#FCA5A5' => 'error-border', '#FECDD3' => 'error-border',
  '#FEF2F2' => 'error-tint', '#FFF1F2' => 'error-tint',
  # warning
  '#EA580C' => 'warning', '#C2410C' => 'warning',
  '#7C2D12' => 'warning-ink',
  '#FED7AA' => 'warning-border', '#FDBA74' => 'warning-border',
  '#FFF7ED' => 'warning-tint',
  # info
  '#2563EB' => 'info', '#1D4ED8' => 'info', '#007BFF' => 'info', '#4338CA' => 'info',
  '#1A4A8A' => 'info-deep', '#1E3A5F' => 'info-deep',
  '#BFDBFE' => 'info-border', '#BFCFE8' => 'info-border',
  '#EBF2FC' => 'info-tint', '#EFF6FF' => 'info-tint', '#F0F9FF' => 'info-tint',
  '#F7F9FF' => 'info-tint',
  # sky (CO)
  '#0369A1' => 'sky', '#00838F' => 'sky', '#075985' => 'sky',
  '#0284C7' => 'sky-bright', '#00ACC1' => 'sky-bright',
  '#BAE6FD' => 'sky-border', '#7DD3FC' => 'sky-border',
  '#E0F2FE' => 'sky-tint', '#E0F7FA' => 'sky-tint',
  # amber (CE)
  '#D97706' => 'amber',
  '#92400E' => 'amber-ink', '#A16207' => 'amber-ink',
  '#FEF3C7' => 'amber-tint', '#FEF9C3' => 'amber-tint', '#FFF9C4' => 'amber-tint',
  # violet
  '#7C3AED' => 'violet', '#6D28D9' => 'violet', '#7E22CE' => 'violet',
  '#4C1D95' => 'violet-deep',
  '#DDD6FE' => 'violet-border', '#C4B5FD' => 'violet-border', '#E9D5FF' => 'violet-border',
  '#F5F3FF' => 'violet-tint', '#EDE9FE' => 'violet-tint', '#FDF4FF' => 'violet-tint',
}.freeze

MAP3 = { '#FFF' => 'surface', '#333' => 'ink', '#666' => 'ink-soft', '#777' => 'ink-faint' }.freeze

RGBA = {
  'rgba(26,107,74,0.06)'  => 'brand-veil',
  'rgba(26,107,74,0.1)'   => 'brand-veil-2',
  'rgba(26,107,74,0.10)'  => 'brand-veil-2',
  'rgba(42,155,111,0.12)' => 'brand-glow',
  'rgba(201,149,42,0.07)' => 'action-veil',
}.freeze

files  = Dir.glob("#{ROOT}/app/views/**/*.erb").reject { |f| f.include?('mailer') }
files += Dir.glob("#{ROOT}/app/helpers/**/*.rb")
files += Dir.glob("#{ROOT}/app/javascript/**/*.js")
files += ["#{ROOT}/app/assets/stylesheets/application.scss",
          "#{ROOT}/app/assets/stylesheets/application.tailwind.css",
          "#{ROOT}/app/assets/stylesheets/_globals.scss"]
files += Dir.glob("#{ROOT}/app/assets/stylesheets/components/*.scss")

stats    = Hash.new(0)
leftover = Hash.new { |h, k| h[k] = [] }
touched  = []

files.each do |path|
  src = File.read(path)
  out = src.dup

  # protege a linha do theme-color (meta tag não aceita var())
  protected_lines = out.lines.map { |l| l.include?('theme-color') }

  new_lines = out.lines.each_with_index.map do |line, i|
    next line if protected_lines[i]

    MAP6.each do |hex, token|
      n = line.scan(/#{Regexp.escape(hex)}/i).size
      next if n.zero?
      line = line.gsub(/#{Regexp.escape(hex)}/i, "var(--#{token})")
      stats["#{hex} → --#{token}"] += n
    end
    MAP3.each do |hex, token|
      n = line.scan(/#{Regexp.escape(hex)}\b/i).size
      next if n.zero?
      line = line.gsub(/#{Regexp.escape(hex)}\b/i, "var(--#{token})")
      stats["#{hex} → --#{token}"] += n
    end
    RGBA.each do |rgba, token|
      lit = Regexp.escape(rgba)
      n = line.scan(/#{lit}/).size
      next if n.zero?
      line = line.gsub(rgba, "var(--#{token})")
      stats["#{rgba} → --#{token}"] += n
    end
    line
  end
  out = new_lines.join

  # hexes que sobraram (fora mailers/theme-color)
  out.lines.each_with_index do |line, i|
    next if protected_lines[i]
    line.scan(/#[0-9A-Fa-f]{6}\b|#[0-9A-Fa-f]{3}\b/).each do |h|
      leftover[h.upcase] << "#{path.sub(ROOT + '/', '')}:#{i + 1}"
    end
  end

  if out != src
    touched << path
    File.write(path, out) if APPLY
  end
end

puts "#{APPLY ? 'APLICADO' : 'DRY-RUN'} — #{touched.size} arquivos alterados, #{stats.values.sum} substituições"
puts "\nTop mapeamentos:"
stats.sort_by { |_, v| -v }.first(15).each { |k, v| puts format('  %4d  %s', v, k) }
puts "\nHex remanescentes (não mapeados): #{leftover.values.flatten.size}"
leftover.sort_by { |_, v| -v.size }.first(15).each do |hex, locs|
  puts "  #{hex} (#{locs.size}×)  ex: #{locs.first}"
end
