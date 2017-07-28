require 'middleman-core/cli'
require 'date'
require 'mini_exiftool'
require 'fileutils'
require 'json'

module Middleman
    module Cli
        class Photo < ::Thor::Group
            include Thor::Actions
            check_unknown_options!
            
            # Template files are relative to this file
            # @return [String]
            def self.source_root
            File.dirname( __FILE__ )
        end
        
        argument :photo_path, type: :string
        
        class_option "date",
        aliases: "-d",
        desc: "The date to create the post with (defaults to now)"
        
        class_option "title",
        aliases: "-t",
        desc: "Title of the picture"
        
        class_option "description",
        aliases: "-s",
        desc: "Title of the picture"
        
        class_option "coordinate",
        aliases: "-c",
        desc: "comma separated coordinates"
        
        def photo
            @photo_path = Pathname.new(photo_path)
            @title = options[:title] || @photo_path.basename.sub_ext("").to_s
            puts options
            @description = options[:description]
            pot_coords = str = options[:coordinate] || ""
            pot_coords = pot_coords.split ","
            if  pot_coords.count == 2 
              lat = pot_coords[0].to_f
              lng = pot_coords[1].to_f
              if !lat.zero? && !lng.zero? 
                @lat = lat
                @lng = lng
              end
            end
            
            throw "File doesn't exist (#{photo_path})" unless @photo_path.exist?
            
            app = ::Middleman::Application.new do
              config[ :mode ]              = :config
              config[ :disable_sitemap ]   = true
              config[ :watcher_disable ]   = true
              config[ :exit_before_ready ] = true
            end
            
            pending_dir = app.extensions[:gallery].options.pending_dir
            
            photo_name = @photo_path.basename.sub_ext("")
            
            dir_path = app.source_dir + "../data/"
            hash = Digest::SHA256.file(photo_path).hexdigest
            temp_file = hash + @photo_path.extname
            FileUtils.cp @photo_path, app.source_dir + pending_dir + temp_file
            File.open(dir_path + (@title.to_s + "_metadata.json"), "w") do |f|
              f.write exif_data.to_json
            end
            File.open(app.source_dir + (@title.to_s + ".html.erb"), "w") do |f|
              data = {
                :title => @title,
                :file => temp_file,
                :publish_date => DateTime.now
              }
              
              if !@lat.nil? && !@lng.nil? 
                data[:latitude] = @lat
                data[:longitude] = @lng
              end
              
              f.write data.to_yaml
              f.write "\n---\n"
              f.write @description
            end
        end
        
        def raw_exif_data
          @_data =  MiniExiftool.new(@photo_path.to_path) if @_data.nil? 
          @_data
        end
        
        def exif_data
            data = raw_exif_data
            return {
                :camera => data.model,
                :iso_speed => data.iso,
                :aperture => data.aperture,
                :exposure => data.exposuretime,
                :lens => data.lensid || data.lensmodel,
                :focal_length => data.focallength.to_i.to_s + " mm",
                :date_taken => data.datecreated || raw_exif_data.DateTimeOriginal || raw_exif_data.CreateDate
            }
        end
        
        Base.register( self, 'photo', 'photo path [options]', 'Create a new photo entry' )
    end
end
end

