import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    port: 3100,
    proxy: {
      '/api': 'http://localhost:3000',
      '/cable': {
        target: 'ws://localhost:3000',
        ws: true,
      },
    },
  },
})
