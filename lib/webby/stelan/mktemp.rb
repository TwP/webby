# :stopdoc:
# Skeleton module for the 'mktemp' routine.
#
# Ideally, one would do this in their code to import the "mktemp" call
# directly into their current namespace:
#
#     require 'mktemp'
#     include MkTemp
#     # do something with mktemp()
#
#
# It is recommended that you look at the documentation for the mktemp()
# call directly for specific usage.
#
#--
#
# The compilation of software known as mktemp.rb is distributed under the
# following terms:
# Copyright (C) 2005-2006 Erik Hollensbe. All rights reserved.
#
# Redistribution and use in source form, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
#++

module Webby
module MkTemp
  VALID_TMPNAM_CHARS = (?a..?z).to_a + (?A..?Z).to_a

  #
  # This routine just generates a temporary file similar to the
  # routines from 'mktemp'. A trailing series of 'X' characters will
  # be transformed into a randomly-generated set of alphanumeric
  # characters.
  # 
  # This routine performs no file testing, at all. It is not suitable
  # for anything beyond that.
  #
  
  def tmpnam(filename)
    m = filename.match(/(X*)$/)
    
    retnam = filename.dup
    
    if m[1]
      mask = ""
      m[1].length.times { mask += VALID_TMPNAM_CHARS[rand(52)].chr }
      retnam.sub!(/(X*)$/, mask) 
    end

    return retnam
  end
  
  module_function :tmpnam

  #
  # This routine works similarly to mkstemp(3) in that it gets a new
  # file, and returns a file handle for that file. The mask parameter
  # determines whether or not to process the filename as a mask by
  # calling the tmpnam() routine in this module. This routine will
  # continue until it finds a valid filename, which may not do what
  # you expect.
  #
  # While all attempts have been made to keep this as secure as
  # possible, due to a few problems with Ruby's file handling code, we
  # are required to allow a few concessions. If a 0-length file is
  # created before we attempt to create ours, we have no choice but to
  # accept it. Do not rely on this code for any expected level of
  # security, even though we have taken all the measures we can to
  # handle that situation.
  #

  def mktemp(filename, mask=true)
    fh = nil

    begin 
      loop do
        fn = mask ? tmpnam(filename) : filename

        if File.exist? fn
          fail "Unable to create a temporary filename" unless mask
          next
        end

        fh = File.new(fn, "a", 0600)
        fh.seek(0, IO::SEEK_END)
        break if fh.pos == 0 
  
        fail "Unable to create a temporary filename" unless mask
        fh.close
      end
    rescue Exception => e
      # in the case that we hit a locked file...
      fh.close if fh
      raise e unless mask
    end
    
    return fh
  end

  module_function :mktemp

  # 
  # Create a directory. If mask is true (default), it will use the
  # random name generation rules from the tmpnam() call in this
  # module.
  #
 
  def mktempdir(filename, mask=true)
    fn = mask ? tmpnam(filename) : filename
    Dir.mkdir(fn)
    return fn
  end

  module_function :mktempdir
end  # module MkTemp
end  # module Webby

# :startdoc:
# EOF
