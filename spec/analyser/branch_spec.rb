require "spec_helper"
require 'backports/2.4.0/hash/transform_values'

module DeepCover
  RSpec.describe Analyser::Branch do
    def line(node)
      node.expression.line rescue binding.pry
    end

    let(:analyser) {
      Analyser::Branch.new(node)
    }
    let(:results) { analyser.results }
    let(:line_runs) { results.map do |node, branches_runs|
        [line(node), branches_runs.map do |branch, runs|
          [line(branch), runs != 0]
        end.to_h]
      end.to_h
    }
    subject { line_runs }

    context 'for a if' do
      let(:node){ Node[ <<-RUBY ] }
        if false
          raise
        else
          "yay"
        end
      RUBY
      it { should == {1 => {2 => false, 4 => true}} }
    end
  end
end