require "middleman-core"
require "middleman-gallery/version"
require "middleman-gallery/extension"

::Middleman::Extensions.register(:gallery) do
    require "middleman-gallery/commands/photo"
    ::Middleman::GalleryExtension
end