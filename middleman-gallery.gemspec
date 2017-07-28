# -*- encoding: utf-8 -*-
$:.push File.expand_path( "../lib", __FILE__ )
require "middleman-gallery/version"

Gem::Specification.new do | s |

  s.name                  = "middleman-gallery"
  s.version               = Middleman::Gallery::VERSION
  s.platform              = Gem::Platform::RUBY
  s.authors               = [ "Diego Torres" ]
  s.email                 = [ "github@dtorres.me" ]
  s.homepage              = "https://github.com/middleman/middleman-blog"
  s.summary               = %q{ Photo gallery engine for Middleman }
  s.description           = %q{ Photo gallery engine for Middleman }
  s.license               = "MIT"
  s.files                 = `git ls-files -z`.split( "\0" )
  s.test_files            = `git ls-files -z -- {fixtures,features}/*`.split( "\0" )
  s.require_paths         = [ "lib" ]
  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency( "middleman-core", [ ">= 4.0.0" ] )
  s.add_dependency( "tzinfo",         [ ">= 0.3.0" ] )
  s.add_dependency( "addressable",    [ "~> 2.3"   ] )
  s.add_dependency( "exifr" )
end
