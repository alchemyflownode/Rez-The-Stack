/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        obsidian: {
          root: '#030405',
          surface: '#0B0C0E',
          panel: '#0F1113',
          elevated: '#151719',
        },
        cyan: {
          primary: '#2DD4BF',
          hover: '#5EEAD4',
          soft: 'rgba(45, 212, 191, 0.15)',
        },
        green: {
          success: '#22C55E',
          soft: 'rgba(34, 197, 94, 0.1)',
        },
        border: {
          subtle: '#1E293B',
          soft: '#334155',
          medium: '#475569',
        },
        text: {
          primary: '#F8FAFC',
          secondary: '#CBD5E1',
          muted: '#94A3B8',
          tertiary: '#64748B',
        },
      },
      animation: {
        'pulse-cyan': 'pulse 2s ease-in-out infinite',
      },
      keyframes: {
        pulse: {
          '0%, 100%': { opacity: '1', transform: 'scale(1)' },
          '50%': { opacity: '0.6', transform: 'scale(1.2)' },
        }
      },
    },
  },
  plugins: [],
}
