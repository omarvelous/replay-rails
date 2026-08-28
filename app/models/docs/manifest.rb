module Docs
  class Manifest
    MANIFEST_PATH = Rails.root.join("config/docs.yml")

    class << self
      def categories
        manifest["categories"]
      end

      def find(slug)
        all_pages.find { |p| p[:slug] == slug }
      end

      def all_pages
        categories.flat_map do |cat|
          cat["pages"].map do |page|
            {
              title: page["title"],
              slug: page["slug"],
              template: page["template"],
              description: page["description"],
              category: cat["name"]
            }
          end
        end
      end

      private

      def manifest
        @manifest ||= YAML.safe_load_file(MANIFEST_PATH)
      end
    end
  end
end
