# QR scan tracking is handled directly in ScansController via
# Ahoy::Tracker. The qr.scanned governed event captures qr_code_id,
# screen_content_id, ad_id, screen_id, and destination_url.
#
# Future: ActiveSupport::Notifications subscriber for holistic
# redirect tracking across all controllers.
