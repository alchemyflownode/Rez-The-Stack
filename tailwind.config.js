/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        'hive': {
          'accent': '#00f2ff',
          'purple': '#bc13fe',
          'orange': '#ff8c00',
          'black': '#050505',
          'white': '#f8fafc',
          'cyan': '#00f2ff',
          'blue': '#3b82f6',
          'green': '#10b981',
          'yellow': '#eab308',
          'red': '#ef4444',
          'rose': '#f43f5e',
        },
        'obsidian': {
          'root': '#030405',
          'surface': '#0b0c0e',
          'panel': '#0f1113',
          'elevated': '#151719',
        }
      },
      fontFamily: {
        'sans': ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        'mono': ['JetBrains Mono', 'monospace'],
        'display': ['Space Grotesk', 'sans-serif'],
      },
      animation: {
        'float': 'float 6s ease-in-out infinite',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'pulse-glow': 'pulse-glow 2s ease-in-out infinite',
        'scanline': 'scanline 8s linear infinite',
        'gradient': 'gradientShift 6s ease infinite',
        'border-flow': 'borderFlow 4s linear infinite',
        'shimmer': 'shimmer 1.5s infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-5px)' },
        },
        'pulse-glow': {
          '0%, 100%': { opacity: '0.5' },
          '50%': { opacity: '1' },
        },
        scanline: {
          '0%': { transform: 'translateY(-100%)' },
          '100%': { transform: 'translateY(100%)' },
        },
        gradientShift: {
          '0%': { backgroundPosition: '0% 50%' },
          '50%': { backgroundPosition: '100% 50%' },
          '100%': { backgroundPosition: '0% 50%' },
        },
        borderFlow: {
          '0%': { backgroundPosition: '0% 0' },
          '100%': { backgroundPosition: '300% 0' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
      },
      backdropBlur: {
        'xs': '2px',
        'sm': '4px',
        'md': '8px',
        'lg': '12px',
        'xl': '16px',
        '2xl': '24px',
        '3xl': '32px',
        '4xl': '48px',
      },
      boxShadow: {
        'premium': '0 20px 40px -15px rgba(0, 0, 0, 0.7), 0 0 0 1px rgba(255, 255, 255, 0.03) inset',
        'elevated': '0 30px 50px -20px rgba(0, 0, 0, 0.8), 0 0 0 1px rgba(255, 255, 255, 0.05) inset',
        'glow-cyan': '0 0 30px rgba(0, 242, 255, 0.3)',
        'glow-purple': '0 0 30px rgba(188, 19, 254, 0.3)',
        'glow-orange': '0 0 30px rgba(255, 140, 0, 0.3)',
        'inner-glow': 'inset 0 0 20px rgba(0, 242, 255, 0.1)',
      },
    },
  },
  plugins: [],
}