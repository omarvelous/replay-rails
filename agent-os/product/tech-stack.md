# Tech Stack

## Backend
- **Rails 8.1** — Full-stack Ruby on Rails
- **PostgreSQL** — Primary database
- **Solid Queue** — DB-backed background job processing (no Redis)
- **Solid Cache** — DB-backed caching (no Redis)
- **Solid Cable** — DB-backed Action Cable (no Redis)

## Frontend
- **Hotwire** — Turbo + Stimulus for SPA-like interactions without a JS framework
- **Importmap** — ES module imports without a bundler (no webpack/vite)
- **Tailwind CSS v4** — Utility-first CSS framework
- **DaisyUI v5** — Semantic component classes on top of Tailwind
- **Propshaft** — Asset pipeline (no Sprockets preprocessing)

## Infrastructure
- **Docker** — Development and production containers
- **Kamal** — Zero-downtime deployment
- **GitHub Actions** — CI/CD pipeline (5-job: scan_ruby, scan_js, lint, test, system-test)
