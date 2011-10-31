$LOAD_PATH.unshift(Dir.pwd)
require 'main'

use Rack::ShowExceptions
use Rack::Static, :urls => ['/js', '/css'], :root => 'public'

run Main.new
