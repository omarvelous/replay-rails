if defined?(Lookbook)
  Rails.application.configure do
    config.lookbook.preview_paths = [ Rails.root.join("spec/components/previews") ]
    config.lookbook.preview_layout = "lookbook_preview"
    config.lookbook.project_name = "RePlay"
    config.lookbook.ui_theme = "indigo"
  end
end
