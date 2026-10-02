import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    port: 3100,
    proxy: {
      '/api': {
        target: process.env.API_URL || 'http://localhost:3000',
        changeOrigin: true,
        headers: { 'Host': 'play.replay.localhost' },
      },
      '/rails/active_storage': {
        target: process.env.API_URL || 'http://localhost:3000',
        changeOrigin: true,
        headers: { 'Host': 'play.replay.localhost' },
      },
      '/cable': {
        target: process.env.WS_URL || 'ws://localhost:3000',
        ws: true,
        headers: { 'Host': 'play.replay.localhost' },
      },
    },
  },
})
