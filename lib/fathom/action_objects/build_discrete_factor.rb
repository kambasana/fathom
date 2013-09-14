=begin

  Build Discrete Factor
  =====================

  Data

  * observations (CSV)
  * variable definitions ({label => [values]})
  * factor

  Primary Course

  User provides variable definitions and observations
  System updates the frequencies from observations
  System replaces zeroes with the default probability (1 / 3 orders of magnitude greater than the observation size)
  System normalizes the frequency table into a probability table
  System returns a factor

=end

require File.expand_path('../build_factor_base', __FILE__)
module Fathom

  class BuildDiscreteFactor < BuildFactorBase

    attr_reader :variables, :observations

    def initialize(variables, observations)
      @variables    = variables
      @observations = observations
    end

    def frequency_table
      return @frequency_table if @frequency_table
      @frequency_table = Hash.new(0)
      data.each do |row|
        @frequency_table[key_for(row)] += 1
      end
      @frequency_table
    end

    def probability_table
      @probability_table ||= normalize_frequencies
    end

    def factor
      @factor ||= Factor.new({
       name: dependent_label,
       properties: independent_labels,
       type: 'discrete',
       table: probability_table
      })
    end
    alias_method :execute!, :factor

    def inspect
      "BuildDiscreteFactor (#{size}) #{dependent_label} from #{independent_labels}"
    end

    protected

    def key_for(row)
      indices.map { |index| row[index] }
    end

    def normalize_frequencies
      table_keys.each do |key|
        frequency_table[key] = default_frequency if frequency_table[key].zero?
      end
      table_keys.inject({}) do |hash, key|
        hash[key] = frequency_table[key] / frequency_sum
        hash
      end
    end

    def frequency_sum
      @frequency_sum ||= frequency_table.inject(0.0) {|s, (k, v)| s + v}
    end

    def size
      @size ||= data.size
    end

    def default_frequency
      ceiling_order_of_magnitude = Math.log10(size).ceil
      three_orders_more = 3 + ceiling_order_of_magnitude
      numerator = 10 ** three_orders_more
      1.0 / numerator
    end

    def indices
      @indices ||= (independent_labels + [dependent_label]).map { |label| header.index(label) }
    end

    def header
      @header ||= observations[0]
    end

    def data
      @data ||= observations[1..-1]
    end

  end

end
