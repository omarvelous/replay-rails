class AddAhoyVisitToLeadsInquiriesQrScans < ActiveRecord::Migration[8.1]
  def change
    add_reference :leads, :ahoy_visit
    add_reference :inquiries, :ahoy_visit
    add_reference :qr_scans, :ahoy_visit
  end
end
