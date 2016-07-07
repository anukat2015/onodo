require 'open3'
require 'csv'

# TODO: This is a poor-man implementation of the interface with the network analysis engine.
# Needs to be replaced with either:
#   - a POST to a network analysis web server. (Simpler, but synchronous.)
#   - a message-based async connection.
class NetworkAnalysis

  def initialize(dataset)
    @relations = dataset.relations
  end

  def calculate_metrics
    results = {}
    python_filename = Rails.root.join('lib', 'network_analysis', 'network_metrics_onodo.py').to_s
    Open3.popen3('python', python_filename) do |stdin, stdout, stderr, wait_thread|
      # Send the list of relations to the processor.
      # One line per relation, two node ids separated with a space.
      @relations.each do |relation|
        stdin.puts "#{relation.source_id} #{relation.target_id}"
      end
      stdin.close

      # Read and parse the output.
      # Note we're ignoring the error output for now.
      columns = nil
      stdout.each do |line|
        values = CSV.parse_line(line.strip)
        next if values.nil? # Ignore empty lines
        if columns.nil?
          columns = values.map &:to_sym
        else
          values_as_dictionary = {}
          columns.each_with_index {|column, i| values_as_dictionary[column] = values[i] }
          results[values[0]] = values_as_dictionary
        end
      end
    end

    # FIXME: What do we do with the results? We'll output them on the screen for now
    puts results
  end

end