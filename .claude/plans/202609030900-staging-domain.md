# Plan: Staging Domain Strategy

## Problem

Staging uses `staging.replaytv.co` as a subdomain of the production
domain. This causes several issues:

- **`tld_length` override** — staging needs `tld_length = 2` to parse
  `app.staging.replaytv.co` correctly. Production uses the default (1).
  This is a config drift that's already caused bugs and will continue to.
- **`default_url_options`** — staging needs explicit host overrides in
  three places. Production doesn't need any of this.
- **Cookies** — cookies set on `.replaytv.co` (with `domain: :all`)
  could leak between staging and production if a user visits both.
  A session cookie from production could be sent to staging, or
  vice versa. This could cause auth issues or data leakage.
- **CORS** — the CORS regex has to match both `*.replaytv.co` and
  `*.staging.replaytv.co`. A separate TLD simplifies to just
  matching the one domain.
- **Mental model** — "staging is a subdomain of production" is
  confusing. Staging should feel like a separate environment, not
  a subsection of production.

## Proposal

Use a separate TLD for staging: `replaytv.dev` or `replaytv-staging.co`
or similar. The staging environment then mirrors production exactly:

| | Production | Staging (current) | Staging (proposed) |
|--|-----------|-------------------|-------------------|
| Root | `replaytv.co` | `staging.replaytv.co` | `replaytv.dev` |
| App | `app.replaytv.co` | `app.staging.replaytv.co` | `app.replaytv.dev` |
| Play | `play.replaytv.co` | `play.staging.replaytv.co` | `play.replaytv.dev` |
| TLD length | 1 (default) | 2 (override) | 1 (default) |
| Cookie domain | `.replaytv.co` | `.staging.replaytv.co` | `.replaytv.dev` |
| URL options | None needed | 3 overrides | None needed |

## Benefits

- **Zero config drift** — staging.rb only needs mailer host, not
  tld_length, default_url_options, or any routing workarounds
- **Cookie isolation** — completely separate domain, no cookie leakage
- **Simpler CORS** — one regex per environment
- **Matches production exactly** — same subdomain parsing, same
  routing, same everything
- **Easier to reason about** — staging is its own thing

## Considerations

- **Cost** — another domain (~$12/year)
- **DNS** — another Cloudflare zone, another set of OpenTofu records
- **Render** — custom domains need to be updated
- **`.dev` TLD** — requires HTTPS (HSTS preloaded by Google). Good
  for staging since we're already on HTTPS, but worth noting.
- **Alternative TLDs** — `replaytv.dev`, `replaytv.test` (reserved,
  won't work publicly), `replay-staging.co`, `staging-replay.tv`

## Migration steps

1. Register the staging domain
2. Add zone to Cloudflare
3. Update OpenTofu staging config with new domain
4. Update Render custom domains
5. Simplify `config/environments/staging.rb` — remove tld_length
   and default_url_options overrides
6. Update CORS config
7. Test all subdomains
