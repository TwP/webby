module CaptureHelper

  # Based on code from Rails

  def content_for(name, content = nil, &block)
    existing_content_for = instance_variable_get("@content_for_#{name}").to_s
    new_content_for      = existing_content_for + (block_given? ? capture(&block) : content)
    instance_variable_set("@content_for_#{name}", new_content_for)
  end

  def capture_erb(*args, &block)
    buffer = eval('_erbout', block.binding)
    capture_erb_with_buffer(buffer, *args, &block)
  end
  alias_method :capture, :capture_erb
  alias_method :capture_block, :capture_erb

  def capture_erb_with_buffer(buffer, *args, &block)
    pos = buffer.length
    block.call(*args)
    # extract the block 
    data = buffer[pos..-1]
    # replace it in the original with empty string
    buffer[pos..-1] = ''
    data
  end  
end  # module CaptureHelper

Webby::Helpers.register(CaptureHelper)
