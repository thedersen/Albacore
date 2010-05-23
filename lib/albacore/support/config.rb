module Albacore
  class << self
  	attr_accessor :yaml_config_folder
  	attr_accessor :log_level

    def configure
      yield(configuration) if block_given?
    end

    def configuration 
      @configuration ||= Configuration.new
    end
  end

  class Configuration
    def initialize
      @paths = {}
      @commands = {}
      @configs = {}
    end

    def add_configuration(name, config)
      @configs[name] = config
      instance_eval(<<-EOM, __FILE__, __LINE__)
        def #{name}(&block)
          config = @configs[:#{name}]
          block.call(config)
        end
      EOM
    end

    def add_path(name, path)
      @paths[name] = path
    end

    def get_path(name)
      @paths[name]
    end

    def add_command(name, path, command)
      @commands[name] = Command.new path, command
    end

    def get_command(name)
      cmd = @commands[name]
      msg = "The '#{name.to_s}' task has not been configured"
      fail msg if cmd.nil?
      cmd.fullpath 
    end

    def has_command?(name)
      @commands.include? name
    end

    def method_missing(symbol, *args)
      case args.count
        when 1
          add_command symbol, nil, args[0]
        when 2
          add_command symbol, args[0], args[1]
        else
          super symbol, *args
      end
    end
  end #Configuration

  class Command
    def initialize(path, command)
      @path = path
      @command = command
    end

    def fullpath
      return @command if @path.nil?

      path = Albacore.configuration.get_path(@path) || @path
      File.join(path, @command)
    end
  end
end