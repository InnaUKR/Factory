# frozen_string_literal: true

class Factory
  def self.new(*arguments, &block)
    if arguments.first.is_a?(String)
      raise NameError unless arguments.first.match?(/^[A-Z]/)
      class_name = arguments.first
      members_names = arguments[1..-1]
    else
      members_names = arguments
    end

    class_implementetion = Class.new do
      attr_accessor *members_names

      class_eval(&block) if block_given?

      define_method :members do
        members_names.each(&:to_sym)
      end

      def initialize(*members_values)
        raise ArgumentError if members_values.length > members.length
        members.zip(members_values).each do |name, value|
          instance_variable_set("@#{name}", value)
        end
      end

      def ==(other)
        members.each do |iv|
          if instance_variable_get("@#{iv}") == other.instance_variable_get("@#{iv}")
          else
            return false
          end
        end
      end

      def [](iv)
        if iv.is_a?(Integer)
          raise IndexError if members.length - 1 < iv || members.length < iv.abs
          instance_variable_get("@#{members[iv]}")
        elsif iv.is_a?(Float)
          instance_variable_get("@#{members[iv.to_i]}")
        else
          raise NameError unless members.include?(iv.to_sym)
          instance_variable_get("@#{iv}")
        end
      end

      def []=(iv, value)
        if iv.is_a?(Integer)
          raise IndexError if members.length - 1 < iv || members.length < iv.abs
          instance_variable_set("@#{members[iv]}", value)
        else
          raise NameError unless members.include?(iv.to_sym)
          instance_variable_set("@#{iv}", value)
        end
      end

      def dig(*args)
        to_h.dig(*args)
      end

      def each(&block)
        to_a.each(&block)
      end

      def each_pair(&block)
        to_h.each_pair(&block)
      end

      def eql?(other)
        self.class == other.class && self == other
      end

      def length
        members.length
      end

      alias_method :size, :length

      def select(&block)
        to_a.select(&block)
      end

      def to_a
        members.map { |iv| instance_variable_get("@#{iv}") }
      end

      alias_method :values, :to_a

      def to_h
        hash = {}
        array_iv_values = to_a
        members.each_with_index do |iv, index|
          hash[iv] = array_iv_values[index]
        end
        hash
      end

      def to_s
        result = ''
        members.each do |iv|
          result << "#{iv}=" + instance_variable_get("@#{iv}").to_s + ', '
        end
        "#<factory #{self.class} #{result[0...-2]}>"
      end

      alias_method :inspect, :to_s

      def values_at(*selector)
        if selector.length == 1
          return to_a.values_at(*selector) if selector.first.is_a? Range
          raise TypeError unless selector.first.is_a? Numeric
          raise IndexError if members.length - 1 < selector.first || members.length < selector.first.abs
          to_a.values_at(*selector.to_i)
        else
          selector.each { |value| raise TypeError unless value.is_a? Numeric }
          to_a.values_at(*selector)
        end
      end
    end

    class_name ? const_set(class_name, class_implementetion) : class_implementetion
  end
end
