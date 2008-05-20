
module Webby::Helpers

# Based on code from Rails and Merb.
#
module CaptureHelper


  def content_for( name, content = nil, &block )
    cur = instance_variable_get("@content_for_#{name}").to_s
    new = if block.nil? then content
          else capture_erb(&block) end

    new = cur + new.to_s
    instance_variable_set("@content_for_#{name}", new)
  end

  # Provides direct acccess to the buffer for this view context
  #
  # ==== Parameters
  # the_binding<Binding>:: The binding to pass to the buffer.
  #
  # ==== Returns
  # DOC
  def _erb_buffer( the_binding )
    eval("_erbout", the_binding, __FILE__, __LINE__)
  end

  # ==== Parameters
  # *args:: Arguments to pass to the block.
  # &block:: The template block to call.
  #
  # ==== Returns
  # String:: The output of the block.
  #
  # ==== Examples
  # Capture being used in a .html.erb page:
  # 
  #   <% @foo = capture do %>
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
      buffer[pos..-1] = ''

      data
    end
  end

  # DOC
  def concat_erb(string, the_binding)
    _erb_buffer(the_binding) << string
  end

end  # module CaptureHelper

register(CaptureHelper)

end  # module Webby::Helpers

# EOF
