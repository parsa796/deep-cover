module DeepCover
  module HasChild
    def self.included(base)
      base.extend ClassMethods
    end

    CHILDREN = {}
    CHILDREN_TYPES = {}

    def initialize(*)
      super
      self.class.validate_children_types(children) unless self.class::CHILDREN.empty?
    end

    module ClassMethods
      def has_child(runs: nil, rewrite: nil, rest: false, **h)
        name, type = h.first
        update_children_const(name, rest: rest)
        define_accessor(name)
        add_runtime_check(name, type)
        define_handler(:"#{name}_runs", runs)
        define_handler(:"rewrite_#{name}", rewrite)
      end

      # Creates methods to return the children corresponding with the given `names`.
      # Also creates constants for the indices of the children.
      def has_children(*names)
        names.each do |name|
          rest = name.to_s.end_with?('__rest')
          if rest
            name = name.to_s.gsub(/__rest$/, '').to_sym
          end
          has_child(name => :any, rest: rest)
        end
      end

      def validate_children_types(nodes)
        mismatches = check_children_types(nodes)
        unless mismatches.empty?
          raise TypeError, "Invalid types for #{self}: #{mismatches}"
        end
      end

      private
      def check_children_types(nodes)
        types = expected_types(nodes)
        nodes_mismatches(nodes, types)
      end

      def expected_types(nodes)
        types = self::CHILDREN.flat_map do |name, i|
          type = self::CHILDREN_TYPES[name]
          if i.is_a?(Range)
            Array.new((nodes[i] || []).size, type)
          else
            type
          end
        end
      end

      def nodes_mismatches(nodes, types)
        nodes = nodes.dup
        nodes[nodes.size...types.size] = nil
        nodes.zip(types).reject do |node, type|
          node_matches_type?(node, type)
        end
      end

      def node_matches_type?(node, expected)
        case expected
        when :any
          true
        when nil
          node.nil?
        when Array
          expected.any? {|exp| node_matches_type?(node, exp) }
        when Class
          node.is_a?(expected)
        when Symbol
          node.is_a?(Node) && node.type == expected
        else
          raise "Unrecognized expected type #{expected}"
        end
      end

      def inherited(subclass)
        subclass.const_set :CHILDREN, {}
        subclass.const_set :CHILDREN_TYPES, {}
        super
      end

      def const_missing(name)
        const_set(name, self::CHILDREN.fetch(name.downcase) { return super })
      end

      def update_children_const(name, rest: false)
        children_map = self::CHILDREN
        already_has_rest = false
        children_map.each do |key, value|
          if value.is_a? Range
            children_map[key] = children_map[key].begin..(children_map[key].end - 1)
            already_has_rest = true
          elsif value < 0
            children_map[key] -= 1
          end
        end
        children_map[name] = if rest
          raise "Can't have two rest childrens" if already_has_rest
          children_map.size..-1
        elsif already_has_rest
          -1
        else
          children_map.size
        end
      end

      def define_accessor(name)
        class_eval <<-end_eval, __FILE__, __LINE__
          def #{name}
            children[#{name.upcase}]
          end
        end_eval
      end

      def define_handler(name, method)
        case method
        when nil
          # Nothing to do
        when Symbol
          alias_method name, method
        when Proc
          define_method(name, &method)
        else
          define_method(name) {|*| method }
        end
      end

      def add_runtime_check(name, type)
        self::CHILDREN_TYPES[name] = type
      end
    end
  end
end