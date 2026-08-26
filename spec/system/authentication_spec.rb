# Authentication system specs have been moved to request specs:
#   spec/requests/accounts_spec.rb (signup)
#   spec/requests/sessions_spec.rb (login, logout)
#
# System specs require Docker DNS resolution for subdomain routing
# (app.replay.localhost). Until solved (dnsmasq container or similar),
# browser-based auth testing lives in request specs.
#
# Re-add system specs when testing JS-dependent behavior:
#   - Stimulus controllers (badge toggle, slideshow, player pairing)
#   - Turbo Frame interactions
#   - Drag-and-drop playlist ordering
