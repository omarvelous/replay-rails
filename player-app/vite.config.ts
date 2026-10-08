/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { storybookTest } from '@storybook/addon-vitest/vitest-plugin';
import { playwright } from '@vitest/browser-playwright';
const dirname = typeof __dirname !== 'undefined' ? __dirname : path.dirname(fileURLToPath(import.meta.url));

// More info at: https://storybook.js.org/docs/next/writing-tests/integrations/vitest-addon
export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    port: 3100,
    allowedHosts: ['.replay.localhost'],
    proxy: {
      '/api': {
        target: process.env.API_URL || 'http://localhost:3000',
        changeOrigin: true,
        headers: {
          'Host': 'play.replay.localhost'
        }
      },
      '/rails/active_storage': {
        target: process.env.API_URL || 'http://localhost:3000',
        changeOrigin: true,
        headers: {
          'Host': 'play.replay.localhost'
        }
      },
      '/cable': {
        target: process.env.WS_URL || 'http://localhost:3000',
        ws: true,
        headers: {
          'Host': 'play.replay.localhost'
        }
      },
      '/ahoy': {
        target: process.env.API_URL || 'http://localhost:3000',
        changeOrigin: true,
        headers: {
          'Host': 'play.replay.localhost'
        }
      }
    }
  },
  test: {
    projects: [{
      extends: true,
      plugins: [
      // The plugin will run tests for the stories defined in your Storybook config
      // See options at: https://storybook.js.org/docs/next/writing-tests/integrations/vitest-addon#storybooktest
      storybookTest({
        configDir: path.join(dirname, '.storybook')
      })],
      test: {
        name: 'storybook',
        browser: {
          enabled: true,
          headless: true,
          provider: playwright({}),
          instances: [{
            browser: 'chromium'
          }]
        }
      }
    }]
  }
});