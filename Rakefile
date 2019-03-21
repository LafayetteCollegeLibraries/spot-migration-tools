$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'spot_migration'

Dir['./lib/tasks/**/*'].each { |f| load "./#{f}" }
