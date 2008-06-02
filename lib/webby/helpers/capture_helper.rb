
module Webby::Helpers

# Based on code from Rails and Merb.
#
module CaptureHelper

  # Called in pages and partials to store up content for later use. Takes a
  # string and/or a block. First, the string is evaluated, and then the
  # block is captured using the capture() helper provided by the template
  # languages. The two are concatenated together.
  #
  # Content is retrieved by calling the method without a string or a block.
  #
  # ==== Parameters
  # obj<Object>:: The key in the conetnt_for hash.
  # string<String>:: Textual content. Defaults to nil.
  # &block:: A block to be evaluated and concatenated to string.
  #
  # ==== Returns
  # Any content associated with the key (or nil).
  #
  # ==== Example
  #   content_for(:foo, "Foo")
  #   content_for(:foo)             #=> "Foo"
  #   content_for(:foo, "Bar")
  #   content_for(:foo)             #=> "FooBar"
  #
  def content_for( obj, string = nil, &block )
    return @_content_for[obj] unless string || block_given?

    cur = @_content_for[obj].to_s
    new = string.to_s + (block_given? ? capture_erb(&block) : "")
    @_content_for[obj] = cur + new
  end

  # Returns true if there is content for the given key. Otherwise returns
  # false.
  #
  # ==== Parameters
  # obj<Object>:: The key in the conetnt_for hash.
  #
  # ==== Example
  #   content_for(:foo, "Foo")
  #   content_for?(:foo)            #=> true
  #   content_for?(:bar)            #=> false
  #
  def content_for?( obj )
    @_content_for.key?(obj)
  end

  # Deletes any content associated with the given object in the content_for
  # hash.
  #
  # ==== Parameters
  # obj<Object>:: The key in the conetnt_for hash.
  #
  # ==== Returns
  # Any content associated with the key (or nil).
  #
  # ==== Example
  #   content_for(:foo, "Foo")
  #   content_for?(:foo)            #=> true
  #   delete_content_for(:foo)
  #   content_for?(:foo)            #=> false
  #
  def delete_content_for( obj )
    @_content_for.delete(obj)
  end

  # This method is used to capture content from an ERB filter evaluation. It
  # is useful to helpers that need to process chunks of data during ERB filter
  # processing.
  #
  # ==== Parameters
  # *args:: Arguments to pass to the block.
  # &block:: The ERB block to call.
  #
  # ==== Returns
  # String:: The output of the block.
  #
  # ==== Examples
  # Capture being used in an ERB page:
  # 
  #   <% @foo = capture_erb do %>
  #     <p>Some Foo content!</p> 
  #   <% end %>
  #
  def capture_erb( *args, &block )
    # get the buffer from the block's binding
    buffer = _erb_buffer(block.binding) rescue nil

    # If there is no buffer, just call the block and get the contents
    if buffer.nil?
      block.call(*args)
    # If there is a buffer, execute the block, then extract its contents
    else
      pos = buffer.length
      block.call(*args)

      # extract the block
      data = buffer[pos..-1]

      # replace it in the original with empty string
      buffer[pos..-1] = ""

      data
    end
  end

  # This method is used to concatenate content into the ERB output buffer.
  # It is usefule to helpers that need to insert transformed text back into
  # the ERB output buffer.
  #
  # ==== Parameters
  # string<String>:: The string to insert into the ERB output.
  # the_binding<Binding>:: The binding to pass to the buffer.
  #
  def concat_erb( string, the_binding )
    _erb_buffer(the_binding) << string
  end

  # Provides direct acccess to the ERB buffer in the conext of the binding.
  #
  # ==== Parameters
  # the_binding<Binding>:: The binding to pass to the buffer.
  #
  # ==== Returns
  # The current ERB output buffer.
  #
  def _erb_buffer( the_binding )
    eval("_erbout", the_binding, __FILE__, __LINE__)
  end

end  # module CaptureHelper

register(CaptureHelper)

end  # module Webby::Helpers

# EOF
