module Facon
  class Expectation
    def initialize(error_generator, expectation_ordering, expected_from, method, method_block, expected_received_count = 1)
      @error_generator = error_generator
      @expectation_ordering = expectation_ordering
      @expected_from = expected_from
      @method = method
      @method_block = method_block
      @expected_received_count = expected_received_count

      @argument_expectation = :any
      @exception_to_raise = nil
      @symbol_to_throw = nil
      @actual_received_count = 0
      @args_to_yield = []
    end

    # Sets up the expected method to return the given value, or the value of the
    # given block.
    def and_return(value, &block)
      Kernel::raise AmbiguousReturnError unless @method_block.nil?

      @return_block = block_given? ? block : lambda { value }
    end

    # Sets up the expected method to yield with the given arguments.
    def and_yield(*args)
      @args_to_yield << args
      self
    end

    # Sets up the expected method to raise the given <code>exception</code>
    # (default: Exception).
    def and_raise(exception = Exception)
      @exception_to_raise = exception
    end

    # Sets up the expected method to throw the given <code>symbol</code>.
    def and_throw(sym)
      @symbol_to_throw = sym
    end

    def with(*args, &block)
      @method_block = block if block
      @argument_expectation = args
      self
    end

    def invoke(args, block)
      begin
        raise @exception_to_raise unless @exception_to_raise.nil?
        throw @symbol_to_throw unless @symbol_to_throw.nil?

        return_value = if !@method_block.nil?
          @method_block.call(*args)
        elsif @args_to_yield.size > 0
          @args_to_yield.each { |curr_args| block.call(*curr_args) }
        else
          nil
        end

        if @return_block
          args << block unless block.nil?
          @return_block.call(*args)
        else
          return_value
        end
      ensure
        @actual_received_count += 1
      end
    end

    # Returns true if the given <code>method</code> and arguments match this
    # Expectation.
    def matches(method, args)
      @method == method && check_arguments(args)
    end

    # Returns true if the given <code>method</code> matches this Expectation,
    # but the given arguments don't.
    def matches_name_but_not_args(method, args)
      @method == method && !check_arguments(args)
    end

    def negative_expectation_for(method)
      false
    end

    private
      def check_arguments(args)
        case @argument_expectation
        when :any then true
        when args then true
        end
      end
  end

  class NegativeExpectation < Expectation
    def initialize(error_generator, expectation_ordering, expected_from, method, method_block, expected_received_count = 0)
      super(error_generator, expectation_ordering, expected_from, method, method_block, expected_received_count)
    end

    def negative_expectation_for(method)
      @method == method
    end
  end
end