module Foreman::Telemetry
  def self.measure(key, value = nil, *metric_options, &block)
    if value.is_a?(Hash) && metric_options.empty?
      metric_options = [value]
      value = value.fetch(:value, nil)
    end
    result = nil
    value  = 1000 * StatsD::Instrument.duration { result = block.call } if block_given?
    StatsD.measure key, value, :metric_options => metric_options
    result
  end

  def self.increment(key, value = 1, *metric_options)
    if value.is_a?(Hash) && metric_options.empty?
      metric_options = [value]
      value = value.fetch(:value, 1)
    end
    StatsD.increment key, (value || 1), :metric_options => metric_options
  end

  def self.gauge(key, value, *metric_options)
    if value.is_a?(Hash) && metric_options.empty?
      metric_options = [value]
      value = value.fetch(:value, nil)
    end
    StatsD.gauge key, value, :metric_options => metric_options
  end
end
