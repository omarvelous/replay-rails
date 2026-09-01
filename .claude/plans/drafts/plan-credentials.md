# Plan: Rails Credentials for Secrets Management (Draft)

## Problem

R2 storage keys and other secrets are managed via Render env vars and
`render.yaml`. This spreads secrets across two places (Render dashboard
+ render.yaml `sync: false` entries) and requires manual setup per
environment. Rails credentials provides a single encrypted file per
environment committed to the repo, unlocked by one master key.

## Goal

Move all secrets into per-environment Rails credentials. The only env
var needed in Render is `RAILS_MASTER_KEY`.

## Items

- **Per-environment credentials** — create `config/credentials/staging.yml.enc` and `config/credentials/production.yml.enc` with separate master keys

- **Migrate R2 config to credentials** — move `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`, and `R2_BUCKET` from env vars into credentials. Update `config/storage.yml` to read from `Rails.application.credentials.dig(:r2, :*)` instead of `ENV[]`

- **Update production.rb** — change ActiveStorage service detection from `ENV["R2_ENDPOINT"].present?` to `Rails.application.credentials.dig(:r2, :endpoint).present?`

- **Clean up render.yaml** — remove R2 env vars from shared groups. Only `RAILS_MASTER_KEY`, `RAILS_LOG_TO_STDOUT`, `RAILS_SERVE_STATIC_FILES`, `DATABASE_URL`, and `RAILS_ENV` remain as env vars

- **Update Render dashboard** — set per-environment `RAILS_MASTER_KEY` (staging key ≠ production key since each has its own encrypted credentials file)

- **Document** — update infrastructure README and contributing guide with how to edit credentials per environment
