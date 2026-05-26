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
      colors: {
        'br-verde': {
          floresta: '#0F3826',
          medio:    '#1A6B4A',
          principal:'#2A9B6F',
          sage:     '#6B8F71',
          pale:     '#E8F5EE',
          mint:     '#F0FAF5',
        },
        'br-dourado': {
          DEFAULT: '#C9952A',
          hover:   '#B8841E',
          claro:   '#E6B65C',
          pale:    '#FBF3E0',
          border:  '#E8C97A',
        },
        'br-azul': {
          DEFAULT: '#1A4A8A',
          medio:   '#2563EB',
          hover:   '#1D4ED8',
          pale:    '#EBF2FC',
          border:  '#BFDBFE',
        },
        'br-bg':      '#F7F5F0',
        'br-bg2':     '#EDEAE4',
        'br-surface': '#FFFFFF',
        'br-border':  '#DDD9D2',
        'br-texto':   '#1C1917',
        'br-texto2':  '#5C5853',
        'br-texto3':  '#9C9892',
        'cefr-a1': '#2A9B6F',
        'cefr-a2': '#2563EB',
        'cefr-b1': '#7C3AED',
        'cefr-b2': '#EA580C',
        'cefr-c1': '#1C1917',
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
