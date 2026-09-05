class CreateInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :inquiries do |t|
      t.timestamps
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :company
      t.string :inquiry_type, null: false, default: "demo_request"
      t.string :interest
      t.text :message
      t.datetime :responded_at
    end
  end
end
