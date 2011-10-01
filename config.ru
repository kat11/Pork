use Rack::Static, urls: [/\/./], root: 'public'
run Rack::File.new 'public/index.html'