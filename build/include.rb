require 'erb'

module Aurora
  def self.file(file, type = :raw)
    INCLUDES.each do |path|
      f = File.read("#{path}/#{file}") rescue nil

      case type
      when :raw
        return f
      when :erb
        template = ERB.new f
      
        template.filename = file
      
        return template.result(binding)
      end if f
    end

    throw "Could not find file '#{file}' in paths"
  end
  
  def self.coffee(file, type = :raw)
    IO.popen("#{AURORA}/node_modules/coffee-script/bin/coffee -bcs", "w+") do |pipe|
      pipe.puts self.file(file, type)
      pipe.close_write
      return pipe.read
    end
  end
end
