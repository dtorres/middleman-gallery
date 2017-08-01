module Middleman
  module Gallery
    class GalleryData
      
      attr_reader :photo_entries
      attr_reader :options
      attr_accessor :app
      
      def initialize(app, options)
        @app = app
        @options = options
        @photo_entries = []
      end
      
      def binary_search(array, value, from=0, to=nil)
        publish_date = value.publish_date
        to = array.count - 1 if to == nil
      
        # from can't be bigger than to
        raise ArgumentError if from > to
      
        # out of range
        raise ArgumentError if from < 0
        raise ArgumentError if to >= array.count
        while true do
          mid = (from + to) / 2
          comparison = publish_date <=> array[mid].publish_date
          # not found
          return -1 if from == to && comparison != 0
      
          case comparison
          when 0 
            if array[mid] == value
              return mid
            else
              return array[from..to].find_index(value) + from
            end
          when 1 
            to = mid - 1
          when -1 
            from = mid + 1
          end
        end    
      end
      
      def previous_photo(photo)
        idx = binary_search(@photo_entries, photo)
        nextIdx = idx+1
        return nil if nextIdx >= @photo_entries.count
        return @photo_entries[nextIdx]
      end
      
      def next_photo(photo)
        idx = binary_search(@photo_entries, photo)
        return nil if idx <= 0
        return @photo_entries[idx-1]

      end
      
      def to_permalink(string)
          result = string.gsub(/-+/, '-')
          result.gsub!(/%([a-f0-9]{2})/i, '--\1--')
          # Remove percent signs that are not part of an octet.
          result.gsub!('%', '-')
          # Restore octets.
          result.gsub!(/--([a-f0-9]{2})--/i, '%\1')
      
          result.gsub!(/&.+?;/, '-') # kill entities
          result.gsub!(/[^%a-z0-9_-]+/i, '-')
          result.gsub!(/-+/, '-')
          result.gsub!(/(^-+|-+$)/, '')
          return result.downcase
      end
      
      def manipulate_resource_list(resources)
        data_path = @app.source_dir + "../data/"
        @photo_entries = []
        resources.each do |resource|
          unless resource.data.file.nil?
            resource.extend Middleman::Gallery::PhotoEntry
            resource.destination_path = to_permalink(resource.data.title)
            resource.gallery = self
            @photo_entries << resource
            
            metadata = JSON.load resource.metadata_path(data_path)
            date = metadata["date_taken"]
            metadata["date_taken"] = Date.parse(date) unless date == nil
      
            resource.add_metadata metadata
            original_file = @app.source_dir + @options.pending_dir + resource.data.file 
            if (File.exist? original_file) && (@app.environment == :development)
              resources << Middleman::Sitemap::Resource.new(@app.sitemap, @options.pending_dir + "/" + resource.data.file, original_file.to_path)
            end
          end
        end
        @photo_entries.sort_by!(&:publish_date).reverse!
        resources += build_pages()
        resources
      end
      
      def build_pages
        return [] unless @options.pagination
        
        template_json_page = Middleman::Sitemap::Resource.new(@app.sitemap, "page/page.json", (@app.source_dir + "layouts" + @options.json_layout).to_path)
        template_json_page.ignored = true
        
        template_page = Middleman::Sitemap::Resource.new(@app.sitemap, "page/page.html", (@app.source_dir + "index.html.erb").to_path)
        template_page.ignored = true
        
        page_count = @options.page_count
        start_idx = @photo_entries.count
        page_idx = 0
        proxy_pages = [template_json_page, template_page]
        store = @app.sitemap
        next_page = nil
        while start_idx > page_count
          end_idx = start_idx
          start_idx = end_idx - page_count
          previous_page = nil
          if start_idx > page_count
            previous_page = "/page/#{page_idx+1}.html"
          else
            previous_page = "/index.html"
          end
          
          metadata = { 
            :entry_indexes => start_idx...end_idx,
            :previous_page => previous_page,
            :next_page => next_page 
          }
          
          json_resource = Middleman::Sitemap::ProxyResource.new(store, "page/#{page_idx}.json", "page/page.json")
          json_resource.add_metadata(metadata)
          proxy_pages << json_resource
          
          html_resource = Middleman::Sitemap::ProxyResource.new(store, "page/#{page_idx}.html", "page/page.html")
          html_resource.add_metadata(metadata)
          proxy_pages << html_resource
          
          next_page = "/page/#{page_idx}.html"
          page_idx += 1
        end
        
        entry_idxs = 0...(start_idx + page_count)
        
        index_resource = @app.sitemap.find_resource_by_path("index.html")
        index_resource.add_metadata({ 
          :entry_indexes => entry_idxs,
          :next_idx => page_idx-2,
          :next_page => "/page/#{page_idx-2}.html"})
        proxy_pages
      end
      
    end
  end
end   