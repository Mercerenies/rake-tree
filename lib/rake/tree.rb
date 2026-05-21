# frozen_string_literal: true

require 'rake'
require 'tempfile'
require 'stringio'

require_relative "tree/version"

module Rake
  module Tree
    class Error < StandardError; end

    class << self

      def produce_graphviz
        Rake.application.load_rakefile
        puts 'digraph rake {'
        Rake::Task.tasks.each do |task|
          task.prerequisites.each do |pre|
            puts %Q(  "#{task.name}" -> "#{pre}")
          end
        end
        puts '}'
      end

      def write_viz(output_file)
        graphviz_io = StringIO.new
        old_stdout = $stdout
        $stdout = graphviz_io
        begin
          produce_graphviz
        ensure
          $stdout = old_stdout
        end
        graphviz_text = graphviz_io.string

        case File.extname(output_file)
        when '.dot'
          File.write(output_file, graphviz_text)
        when '.png'
          with_temp_dot graphviz_text do |filename|
            `dot -Tpng #{filename} -o #{output_file}`
          end
        when '.svg'
          with_temp_dot graphviz_text do |filename|
            `dot -Tsvg #{filename} -o #{output_file}`
          end
        end
      end

      private def with_temp_dot(contents, &block)
        Tempfile.open(['rake-tree', '.dot']) do |file|
          file.write(contents)
          file.flush
          block.call file.path
        end
      end
    end
  end
end
