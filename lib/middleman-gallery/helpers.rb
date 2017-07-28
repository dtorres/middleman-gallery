module Middleman
  module Gallery
    # Blog-related helpers that are available to the Middleman application in +config.rb+ and in templates.
    module Helpers
      
      def gallery
        app.extensions[:gallery].data
      end
    end
  end
end