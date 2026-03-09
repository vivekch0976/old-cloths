import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}'
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f4f7f5',
          100: '#e6efe9',
          500: '#2d6a4f',
          700: '#1f4c39'
        }
      }
    }
  },
  plugins: []
};

export default config;
