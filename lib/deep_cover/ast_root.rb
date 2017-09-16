require 'backports/2.1.0/enumerable/to_h'
require_relative 'has_tracker'
require_relative 'has_child'
require_relative 'node'

module DeepCover
  class AstRoot
    include HasTracker
    include HasChild

    has_tracker :root
    has_child main: Node

    attr_reader :file_coverage

    def initialize(child_ast, file_coverage)
      @file_coverage = file_coverage
      @main_node = Node.augment(child_ast, file_coverage, self)
      super()
    end

    def child_flow_entry_count(_child)
      root_tracker_hits
    end

    def child_prefix(_child)
      "((#{root_tracker_source};"
    end

    def child_suffix(_child)
      "))"
    end

    def children
      [@main_node]
    end
  end
end
