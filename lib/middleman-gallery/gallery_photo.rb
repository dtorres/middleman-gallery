module Middleman
  module Gallery
    module PhotoEntry
      
      attr_accessor :gallery
      attr_accessor :photo_meta
      def render(opts={}, locs={}, &block)
        opts[:layout] = metadata[:options][:layout]
        super(opts, locs, &block)
      end
      
      def original_path
        gallery.options.pending_dir + "/" + data.file
      end 
      
      def publish_date
        data.publish_date
      end

      def date_taken
        @photo_meta["date_taken"]
      end
      
      def title
        data.title
      end
      
      def server
        gallery.options.cdn_url
      end
      
      def img_src
        local_path = original_path
        app = gallery.app
        if (app.environment == :development && app.sitemap.find_resource_by_path(local_path))
          return "/"+ local_path.to_s
        else
          return server + File.basename(data.file, ".*") + File.extname(data.file)
        end
      end

      def img_size
        sizes = @photo_meta["sizes"]
        sizes["large"] if sizes
      end

      def coordinate
        if (lat = data.latitude) && (lng = data.longitude)
          return [lat, lng]
        end
        nil
      end

      def map_zoom_level
        if (level = data.zoom_level)
          return level
        end
        16
      end
      
      def thumb_src(size)
        local_path = original_path
        app = gallery.app
        if (app.environment == :development && app.sitemap.find_resource_by_path(local_path))
          return "/"+ local_path.to_s
        end
        server + "thumbs/" + thumb_filename(size)
      end
      
      def metadata_path(data_path = nil)
        data_path = data_path || gallery.app.source_dir + "../data/"
        meta_path = data_path + (File.basename(data.file, ".*") + "_metadata.json")
        return meta_path if File.exist? meta_path
        
        #Backwards compatibility
        meta_path = data_path + (File.basename(self.path, ".*") + "_metadata.json")
        return meta_path
      end

      def _setup_metadata
        meta_path = metadata_path
        if File.exist? meta_path
         @photo_meta = JSON.load(meta_path)
         a_date = @photo_meta["date_taken"]
         @photo_meta["date_taken"] = Date.parse(a_date) unless a_date == nil
        else
          @photo_meta = {}
        end
      end
      
      def thumb_filename(size)
        #TODO: Enforce sizes in gallery
        File.basename(data.file, ".*") + "_" + size.to_s + File.extname(data.file)
      end
      
      def next_photo
        gallery.next_photo(self)
      end
      
      def previous_photo
        gallery.previous_photo(self)
      end
      
      def inspect
        "#<Middleman::Gallery::PhotoEntry: #{data.inspect}>"
      end
    end
  end
end