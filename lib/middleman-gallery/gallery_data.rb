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
        resources
      end
      
    end
  end
end   