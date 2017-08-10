require 'active_support/time_with_zone'
require 'active_support/core_ext/time/zones'
require 'active_support/core_ext/time/acts_like'
require 'active_support/core_ext/time/calculations'
require 'middleman-gallery/helpers'
require 'middleman-gallery/gallery_photo'
require 'middleman-gallery/gallery_data'
require 'mini_exiftool'
require 'mini_magick'
require 'image_optim'
require 'fastimage'

module Middleman
  class GalleryExtension < Extension
    
    option :layout, 'photoentry', 'ITEM'
    option :pending_dir, '_pending_pictures', 'Path where pending pictures reside'
    option :thumb_sizes, [], 'Thumbnail sizes to be generated, will be mapped to [small, medium]'
    option :cdn_url, "/", 'Where the photos/thumbnails reside, defaults to root of hosting'
    option :pagination, false, "Should we paginate"
    option :page_count, 20, "Number of items per page"
    option :page_layout, "index.html.erb", "Layout for pages, defaults to same as index"
    option :json_layout, "page.json.erb", "Layout for JSON pages"
    option :page_json, true, "Generate json for the pages"
    
    attr_reader :data
    
    self.defined_helpers = [ Middleman::Gallery::Helpers ]
    
    def before_build
      pending_dir = @app.source_dir + options.pending_dir
      assets_dir =  @app.source_dir + "_assets"
      thumbs_dir = assets_dir + "thumbs"
      max_width = 1920
      optimizer = ImageOptim.new(:allow_lossy => true)
      asset_paths = []
      to_resize = {}
      thumbs_to_gen = []
      thumb_sizes = options.thumb_sizes
      resized_res = Set.new
      
      FileUtils.mkdir_p thumbs_dir
      
      @app.sitemap.resources.each do |resource|
        next unless resource.is_a? Middleman::Gallery::PhotoEntry
        asset_path = assets_dir + resource.data.file
        original_file = pending_dir + resource.data.file
        next if !File.exist? original_file
        
        if !File.exist? asset_path
          image = MiniMagick::Image.open(original_file) 
          asset_paths << asset_path         
          if image.width > max_width
            to_resize[asset_path] = image
            resized_res << resource
          else
            FileUtils.mv original_file asset_path
          end
        end
        sizes_to_gen = {}
        thumb_sizes.each { |width| 
          path = thumbs_dir + resource.thumb_filename(width)
          next if File.exist? path
          sizes_to_gen[width] = path
        }
        
        asset_paths += sizes_to_gen.values
        
        if sizes_to_gen.count > 0 
          resized_res << resource
          thumbs_to_gen << {
            :original_path => original_file,
            :sizes => sizes_to_gen
          }
        end
      end
      
      to_resize.in_threads(4).each do |asset_path, image|
        image.combine_options do |b|
          b.quality 100
          b.resize max_width.to_s
        end
        image.write asset_path
      end
      
      thumbs_to_gen.in_threads(4).each do |info|
        original_path = info[:original_path]
        info[:sizes].each do |size, path|
          image = MiniMagick::Image.open(original_path)
          image.combine_options do |b|
            b.quality 100
            b.resize size.to_s + "x"
          end
          image.write path
        end
      end
      
      write_sizes(resized_res)
      optimizer.optimize_images!(asset_paths)
    end
    
    def write_sizes(resources)
      data_path = @app.source_dir + "../data/"
      assets_path = @app.source_dir	+ "_assets"
      thumbs_path = assets_path + "thumbs"
      resources.each do |res|
        raise "Not Photo Entry #{res.path}" unless res.is_a? Middleman::Gallery::PhotoEntry
        path = res.metadata_path(data_path)
        metadata = {"sizes" => {}}
        large_path = assets_path + res.data.file
        large_size = FastImage.size(large_path)
        puts large_path
        unless large_size.nil?
          metadata["sizes"]["large"] = {
            "width" => large_size[0],
            "height" => large_size[1]
          }
        end
        
        ["small", "medium"].zip(options.thumb_sizes).each do |m|
          size_name = m[0]
          width = m[1]
          next if size_name.nil? || width.nil?
          name = File.basename(res.data.file, ".*")
          thumb_path = thumbs_path + (name + "_" + width.to_s + File.extname(res.data.file))
          size = FastImage.size(thumb_path)
          next if size.nil?
          
          metadata["sizes"][size_name] = {
            "width" => size[0],
            "height" => size[1]
          }
        end
        
        res.add_metadata metadata
        old_meta = JSON.load path
        old_meta["sizes"] ||= {}
        puts metadata
        metadata["sizes"].each do |k,v|
          old_meta["sizes"][k] = v
        end
        puts old_meta
        File.open(path, "w") do |f|
          f.write old_meta.to_json
        end
      end
    end
    
    def after_configuration
      @data = Gallery::GalleryData.new(@app, options)
      @app.sitemap.register_resource_list_manipulator(:"gallery_entries", @data)
    end
  end
end
