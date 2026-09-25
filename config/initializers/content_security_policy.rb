# Content Security Policy — browser-level XSS mitigation.
#
# External resources:
#   cdn.jsdelivr.net   — TailwindPlus Elements (app layout)
#   unpkg.com          — Swagger UI JS + CSS (docs page)
#   *.r2.cloudflarestorage.com — Active Storage images (production)
#
# Inline scripts use nonces (importmap, chartkick, player JS).
# Inline styles require unsafe-inline (~425 style= attributes).

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self
    policy.img_src     :self, :data, "https://*.r2.cloudflarestorage.com"
    policy.object_src  :none
    policy.script_src  :self, "https://cdn.jsdelivr.net", "https://unpkg.com"
    policy.style_src   :self, "https://unpkg.com", :unsafe_inline
    policy.connect_src :self
    policy.form_action :self
    policy.frame_ancestors :none
  end

  # Nonce-based script loading for importmap + inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Report violations without enforcing — monitor logs before switching to enforcement.
  config.content_security_policy_report_only = true
end
