
module Kernel

  # :stopdoc:
  WINDOWS = %r/djgpp|(cyg|ms|bcc)win|mingw/ =~ RUBY_PLATFORM
  DEV_NULL = WINDOWS ? 'NUL:' : '/dev/null'
  # :startdoc:

  def cmd_available?( *args )
    io = [STDOUT.dup, STDERR.dup]
    STDOUT.reopen DEV_NULL
    STDERR.reopen DEV_NULL
    system(*(args.flatten))
  ensure
    STDOUT.reopen io.first
    STDERR.reopen io.last
    $stdout, $stderr = STDOUT, STDERR
  end
end  # module Kernel

# EOF
