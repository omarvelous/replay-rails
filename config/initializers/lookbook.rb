if defined?(Lookbook)
  Rails.application.configure do
    preview_path = Rails.root.join("spec/components/previews")

    config.view_component.preview_paths = [ preview_path ]
    config.view_component.show_previews = true

    config.lookbook.preview_paths = [ preview_path ]
    config.lookbook.preview_layout = "lookbook_preview"
    config.lookbook.project_name = "RePlay"
    config.lookbook.ui_theme = "indigo"
  end
end
