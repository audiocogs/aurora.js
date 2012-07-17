AURORA = File.dirname(__FILE__)

LIB = "#{AURORA}/lib"
INCLUDES = ["#{AURORA}/src", "#{AURORA}/"]

$:.unshift AURORA

require 'build/include'

task :build do
  output = File.new("#{LIB}/aurora.js", 'w+')

  # output << beautify(file('aurora.erb.js', :erb))

  output << Aurora.file('aurora.erb.js', :erb)

  output.close
end

task :server do
  require 'webrick'
  require 'ruby-prof'
  
  server = WEBrick::HTTPServer.new(:Port => 3030)
  
  server.mount_proc('/aurora.js') do |req, res|
    res.status = 200
    res['Content-Type'] = 'application/javascript'
    
    RubyProf.start
    res.body = Aurora.file('aurora.erb.js', :erb)
    RubyProf::FlatPrinter.new(RubyProf.stop).print(STDOUT)
  end
  
  server.start
end

# begin
#   require 'jasmine'
#   load 'jasmine/tasks/jasmine.rake'
# rescue LoadError
#   task :jasmine do
#     abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
#   end
# end
