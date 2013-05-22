require 'pry'
require 'pry-stack_explorer'
require 'yaml'

class PraiseImpl
  attr_reader :enabled

  # @param [Proc] outputter a proc which ouputs/logs messages
  # @param [true, false] enabled
  # @param [String] ignored_path path to a yaml file with rules for ignored exceptions
  # @example initialization
  #     Praise = PraiseImpl.
  #         new(File.join(root, Katello.early_config.praise.ignored_path),
  #             -> level, message { Logging.logger['praise'].add Logging.level_num(level), message })
  def initialize(ignored_path, enabled = true, outputter = -> level, message { $stderr.puts message })
    @outputter = outputter
    unless File.exist? ignored_path
      log :info, "creating #{ignored_path} file"
      File.open(ignored_path, 'w') { |f| f.write [].to_yaml }
    end
    @ignored_path = ignored_path
    @enabled      = false
    reload

    self.enabled = enabled
  end

  # @return [Array<Hash{:class, :message, :line => Regexp, String}>] rules for exception ignoring
  def ignored
    @ignored ||= YAML.load File.read(@ignored_path)
  end

  # @param [Hash{:class, :message, :line => Regexp, String}] rule for ignoring an exception
  # This will add a rule for exception ignoring. Can be called at runtime, next exception occurrence will be ignored.
  def add_rule(rule)
    ignored = File.open(@ignored_path, 'r') { |f| YAML.load(f.read) }
    File.open(@ignored_path, 'w') { |f| f.write(ignored.push(rule).to_yaml) }
    reload
  end

  # use to enable or disable Praise
  def enabled=(value)
    return if @enabled == value

    if value
      install
    else
      uninstall
    end
  end

  # @return [true, false] should the exception ignored?
  def ignore?(exception_instance, message, risen_at)
    ignored.any? do |hash|
      hash.all? do |type, condition|
        case type
        when :class
          exception_instance.class.to_s == condition
        when :message
          message =~ condition
        when :line
          risen_at =~ condition
        end
      end
    end.tap do |ignore|
      log :debug, "ignored exception: (#{exception_instance.class}) #{message}\n    #{risen_at}" if ignore
    end
  end

  private

  # reload ignored form file
  def reload
    @ignored = nil
    ignored
  end

  # log `message` on `level`
  def log(level, message)
    @outputter.call(level, message)
  end

  def install
    log :info, 'installing praise'
    praise = self
    Kernel.module_eval do
      define_method :_original_raise, Kernel.instance_method(:raise)

      remove_method :raise
      Thread.current[:__pry_in_rescue__] = false

      define_method :raise do |*args|
        begin
          message             = args.find { |o| o.kind_of? String }
          backtrace           = args.find { |o| o.kind_of? Array }
          exception_generator = args.find { |o| ![message, backtrace].include? o } || RuntimeError
          #noinspection RubyArgCount
          exception           = message ? exception_generator.exception(message) : exception_generator.exception
          message             ||= exception.message
          risen_at            = caller(1).first

          unless Thread.current[:__pry_in_rescue__] || praise.ignore?(exception, message, risen_at)
            Thread.current[:__pry_in_rescue__] = true
            binding.pry
          end

          _original_raise *args
        ensure
          Thread.current[:__pry_in_rescue__] = false
        end
      end

      # TODO alias fail as well, currently does not work with thin
      #remove_method :fail
      #alias_method :fail, :raise
    end
    self
  end

  def uninstall
    Kernel.module_eval do
      define_method :raise, Kernel.instance_method(:_original_raise)
    end
  end
end
