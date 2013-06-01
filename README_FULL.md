# Praise

`pry + raise = praise`

A small gem intercepting all `#raise` calls spawning `pry` sessions to investigate. There is
runtime-editable config file to set ignore patterns for unwanted `raise calls`. The gem is targeting
investigation of re-risen and masked-by-another exceptions.

-   Documentation: <http://blog.pitr.ch/praise>
-   Source: <https://github.com/pitr-ch/praise>
-   Blog: <http://blog.pitr.ch/blog/categories/praise/>


## Difference between `prise` and `pry-rescue`

Praise allows a developer to investigate all exceptions including the ones rescued later.
`pry-rescue` on the other hand will work only for exceptions which are un-handled by the process.
Typical use-case is e.g. a worker, which is rescuing all exceptions. `pry-rescue` cannot help with
investigation of these exceptions.

## Install

1.  require the gem early, e.g. in `contig/application.rb` in rails
2.  install `Praise`, e.g.

        Praise = PraiseImpl.
            new(File.join(root, Katello.early_config.praise.ignored_path),
                true,
                -> level, message { Logging.logger['praise'].add Logging.level_num(level), message })

And that's it.

## Usage

Whenever an exception is risen and exception is not ignored then you will be dropped to a Pry session.

    From: /Users/pitr/Workspace/personal/praise/lib/praise.rb @ line 75 Kernel#raise:

        64: define_method :raise do |*args|
        65:   begin
        66:     message             = args.find { |o| o.kind_of? String }
        67:     backtrace           = args.find { |o| o.kind_of? Array }
        68:     exception_generator = args.find { |o| ![message, backtrace].include? o } || RuntimeError
        69:     exception           = message ? exception_generator.exception(message) : exception_generator.exception
        70:     message             ||= exception.message
        71:     risen_at            = caller(1).first
        72:
        73:     unless Thread.current[:__pry_in_rescue__] || praise.ignore?(exception, message, risen_at)
        74:       Thread.current[:__pry_in_rescue__] = true
     => 75:       binding.pry
        76:     end
        77:
        78:     _original_raise *args
        79:   ensure
        80:     Thread.current[:__pry_in_rescue__] = false
        81:   end
        82: end

    [1] pry(#<Delayed::Backend::ActiveRecord::Job>)>

Stack can be explored with pry-stack_explorer plugin for Pry:

    pry-stack_explorer (v0.4.9)
      down               Go down to the callee's context.
      frame              Switch to a particular frame.
      show-stack         Show all frames
      up                 Go up to the caller's context.

Use `up` or `frame 1` to get to the binding and line where the exception was risen.
When you hit `C-d` exception is risen as usual.

## Ignoring

If there were no method to ignore some exceptions, It would drop to pry for every single `#raise` call, which
would not be very useful. Therefore there is a yml file where filters can be specified to ignore exceptions.
It can be updated at runtime {PraiseImpl#add_rule}.

### Ignore file structure

    [{ class:   'AClass' },         # exception ignored when exception.class.to_s == 'AClass'
     { message: /missing plugin/ }, # exception ignored when exception.message =~ /missing plugin/
     { line:    /rubygems/ },       # exception ignored when risen_at =~ /rubygems/
     { class:   RuntimeError, message: /nothing/ }
     # exception ignored when both rules are met
    ].to_yaml
