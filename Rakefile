AURORA = File.dirname(__FILE__)

LIB = "#{AURORA}/lib"
INCLUDES = ["#{AURORA}/src", "#{AURORA}/"]

$:.unshift AURORA

require 'build/include'

task :build do
  require 'json'

  output = File.new("#{LIB}/aurora.js", 'w+')

  Thread.current[:path] = INCLUDES

  output << Aurora.file('aurora.erb.js', :type => :erb)

  output.close

  Dir.glob("#{AURORA}/plugins/**/plugin.aurora") do |filename|
    json = JSON.load(File.open(filename).read)

    output = File.new("#{LIB}/#{json['output']}", 'w+')

    Thread.current[:path] = ["#{File.dirname(filename)}/src/"]

    output << Aurora.file("#{json['source']}", :type => :erb)

    output.close
  end
end

task :server do
  require 'json'
  require 'webrick'

  server = WEBrick::HTTPServer.new(:Port => 3030)

  server.mount_proc('/aurora.js') do |req, res|
    res.status = 200
    res['Content-Type'] = 'application/javascript'

    Thread.current[:path] = INCLUDES

    res.body = Aurora.file('aurora.erb.js', :type => :erb)
  end

  Dir.glob("#{AURORA}/plugins/**/plugin.aurora") do |filename|
    json = JSON.load(File.open(filename).read)

    server.mount_proc("/plugins/#{json['output']}") do |req, res|
      res.status = 200
      res['Content-Type'] = 'application/javascript'

      Thread.current[:path] = ["#{File.dirname(filename)}/src/"]

      res.body = Aurora.file("#{json['source']}", :type => :erb)
    end
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
