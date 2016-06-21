require_relative 'parse_failure_exception'

# TODO: fail if recording gets too large ...
module Saxinator
  class Parser < ::Nokogiri::XML::SAX::Document
    READ_BUFFER_SIZE     = 256
    ERROR_CONTEXT_LENGTH = 200

    # stack frames
    #  (combinator, can_fail?, [recording_index])
    def initialize(combinator, debug_mode = false)
      @debug_mode       = debug_mode
      @final_result     = nil
      @recording        = []
      @recording_index  = 0
      @combinator_stack = []
      push(combinator, false)
    end


    # Nokogiri::XML::SAX::Document overrides
    def start_element(name, attrs = [])
      record(:action_start_element, name, attrs)
    end

    def characters(string)
      record(:action_characters, string)
    end

    def end_element(name)
      record(:action_end_element, name)
    end

    def end_document
      record(:action_end_document)
    end


    # actions
    def action_start_element(name, attrs = [])
      return if should_ignore_tag?(name)
      check_combinator
      guard { top_combinator.start_element(self, name, attrs) }
    end

    def action_characters(string)
      check_combinator
      guard { top_combinator.characters(self, string) }
    end

    def action_end_element(name)
      return if should_ignore_tag?(name)
      check_combinator
      guard { top_combinator.end_element(self, name) }
    end

    def action_end_document
      guard { top_combinator.end_document(self) } unless @combinator_stack.empty?
    end


    def record(method, *args)
      @recording.push([[method, *args], @io.pos])
    end

    def flush_recording
      loop do
        break unless play_next_action
      end
    end

    def play_next_action
      if @recording_index == 0 && !top_can_fail?
        # no need to preserve recording
        action = @recording.shift
      elsif @recording_index < @recording.length
        # we must preserve the recording in case a failure occurs in the future
        action = @recording[@recording_index]
        @recording_index += 1
      else
        # at end of recording
        action = nil
      end

      action &&= action.first

      self.send(*action) if action
      action
    end


    def push(child_combinator, can_fail)
      @combinator_stack.push([child_combinator, can_fail || top_can_fail?, can_fail ? @recording_index : nil])
      child_combinator.initialize_parse(self)
    end

    def pop(result)
      @combinator_stack.pop
      chop_recording_if_needed

      if top_combinator
        top_combinator.continue(self, result)
      else
        @final_result = result
        # TODO: raise error if anything left on recording ...
      end
    end

    def chop_recording_if_needed
      return if top_can_fail?

      @recording.shift(@recording_index)
      @recording_index = 0
    end

    def guard
      begin
        yield
      rescue ParseFailureException => e
        roll_back(e)
      end
    end

    def roll_back(e)
      loop do
        raise e unless top_can_fail? # nobody caught the exception

        index = top_recording_index
        @combinator_stack.pop

        if index
          # jump back to earlier point in recording
          @recording_index = index
          break
        end
      end

      # TODO?: raise error if there is no combinator at the top ...
      # TODO: don't allow recursion ...
      guard { top_combinator.child_failed(self) }
    end


    def parse(html)
      @io = get_io(html)

      begin
        inner_parse
      rescue ParseFailureException => e
        pos = @recording[@recording_index]
        pos &&= pos.first
        if @debug_mode && pos
          raise e, "#{e.message}\ncharacter #{pos}:\n\n#{text_around_pos(pos)}\n"
        else
          raise e
        end
      end
    end


    private

    def text_around_pos(pos)
      first = [0,          pos - ERROR_CONTEXT_LENGTH].max
      last  = [@io.length, pos + ERROR_CONTEXT_LENGTH].min

      @io.pos = first
      s = @io.read(last - first + 1)

      s[0..(pos-first-2)] + '(*HERE*)' + s[(pos-first-1)..last]
    end

    def inner_parse
      Nokogiri::HTML::SAX::PushParser.new(self).tap do |parser|
        while (buffer = @io.read(read_buffer_size))
          parser << buffer
        end
        parser.finish
        flush_recording
      end

      # TODO: clean up memory ...
      @final_result
    end

    # Nokogiri has bug when it tries to handle IO streams with broken XML/valid HTML tags
    def get_io(html)
      @parties_io ||= html.respond_to?(:read) ? html : StringIO.new(html)
    end

    def read_buffer_size
      @debug_mode ? 1 : READ_BUFFER_SIZE
    end

    def should_ignore_tag?(name)
      name == 'html' || name == 'body' || name == 'p' || name == 'br'
    end

    def top_combinator
      top && top.first
    end

    def top_can_fail?
      !!(top && top[1])
    end

    def top_recording_index
      top && top[2]
    end

    def top
      @combinator_stack.last
    end

    def check_combinator
      raise ParseFailureException, 'Parser failed to consume the entire document' unless top_combinator
    end
  end
end