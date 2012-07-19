require 'erb'

module Aurora
  def self.file(file, opts = {})
    opts = {
      :type => :raw,
      :path => Thread.current[:path]
    }.merge(opts)

    opts[:path].each do |path|
      f = File.read("#{path}/#{file}") rescue nil

      case opts[:type]
      when :raw
        return f
      when :erb
        template = ERB.new f

        template.filename = file

        return template.result(binding)
      end if f
    end

    throw "Could not find file '#{file}' in paths (#{opts[:path].join(', ')})"
  end

  def self.coffee(file, opts = {})
    IO.popen("#{AURORA}/node_modules/coffee-script/bin/coffee -bcs", "w+") do |pipe|
      pipe.puts self.file(file, opts)
      pipe.close_write
      return pipe.read
    end
  end
end
