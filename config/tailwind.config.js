const daisyui = require('daisyui')
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      // Cores lêem os design tokens (app/assets/stylesheets/_tokens.scss).
      // Nomes de classe iguais em toda a franquia Practice; a paleta muda por app.
      colors: {
        brand: {
          deep:     'var(--brand-deep)',
          DEFAULT:  'var(--brand)',
          bright:   'var(--brand-bright)',
          soft:     'var(--brand-soft)',
          'tint-2': 'var(--brand-tint-2)',
          tint:     'var(--brand-tint)',
          mist:     'var(--brand-mist)',
        },
        action: {
          DEFAULT: 'var(--action)',
          hover:   'var(--action-hover)',
          bright:  'var(--action-bright)',
          border:  'var(--action-border)',
          soft:    'var(--action-soft)',
          tint:    'var(--action-tint)',
          ink:     'var(--action-ink)',
        },
        ink: {
          DEFAULT: 'var(--ink)',
          soft:    'var(--ink-soft)',
          faint:   'var(--ink-faint)',
        },
        paper:     { DEFAULT: 'var(--paper)', 2: 'var(--paper-2)' },
        surface:   { DEFAULT: 'var(--surface)', 2: 'var(--surface-2)' },
        line:      { DEFAULT: 'var(--line)', soft: 'var(--line-soft)' },
        'cefr-a1': 'var(--brand-bright)',
        'cefr-a2': 'var(--info)',
        'cefr-b1': 'var(--violet)',
        'cefr-b2': 'var(--warning)',
        'cefr-c1': 'var(--ink)',
      },
      fontFamily: {
        display: ['Raleway', 'sans-serif'],
        body:    ['Plus Jakarta Sans', ...defaultTheme.fontFamily.sans],
        mono:    ['DM Mono', ...defaultTheme.fontFamily.mono],
      },
      borderRadius: {
        'br-sm': '8px',
        'br':    '12px',
        'br-lg': '18px',
        'br-xl': '24px',
      },
    },
  },
  plugins: [daisyui],
  daisyui: {
    // DaisyUI exige valores literais (converte para oklch no build).
    // Esta paleta ESPELHA _tokens.scss — mudou lá, muda aqui.
    themes: [
      {
        'practice-br': {
          'primary':          '#C9952A',
          'primary-content':  '#FFFFFF',
          'secondary':        '#0F3826',
          'secondary-content':'#FFFFFF',
          'accent':           '#2563EB',
          'accent-content':   '#FFFFFF',
          'neutral':          '#1C1917',
          'base-100':         '#F7F5F0',
          'base-200':         '#EDEAE4',
          'base-300':         '#DDD9D2',
          'base-content':     '#1C1917',
          'success':          '#2A9B6F',
          'error':            '#C0392B',
          'warning':          '#D97706',
          'info':             '#2563EB',
        },
      },
    ],
    darkTheme: false,
    base: true,
    styled: true,
    utils: true,
  },
}
