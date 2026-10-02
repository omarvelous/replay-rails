import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    port: 3100,
    proxy: {
      '/api': process.env.API_URL || 'http://localhost:3000',
      '/cable': {
        target: process.env.WS_URL || 'ws://localhost:3000',
        ws: true,
      },
    },
  },
})
