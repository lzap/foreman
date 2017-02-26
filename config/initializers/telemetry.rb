require 'statsd-instrument'
require 'socket'

if Rails.env.test?
  StatsD.backend = StatsD::Instrument::Backends::NullBackend.new
else
  if SETTINGS[:telemetry_destination] == 'logger'
    StatsD.backend = StatsD::Instrument::Backends::LoggerBackend.new(::Foreman::Logging.logger('telemetry'))
  elsif SETTINGS[:telemetry_destination] == 'statsd'
    target = "#{SETTINGS[:telemetry_statsd_host]}:#{SETTINGS[:telemetry_statsd_port]}"
    StatsD.backend = StatsD::Instrument::Backends::UDPBackend.new(target, SETTINGS[:telemetry_statsd_protocol].to_sym)
  else
    StatsD.backend = StatsD::Instrument::Backends::NullBackend.new
  end
end
StatsD.prefix = SETTINGS[:telemetry_prefix] if SETTINGS[:telemetry_prefix]

ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  controller = event.payload[:controller]
  action = event.payload[:action]
  format = event.payload[:format] || "all"
  format = "any" if format == "*/*"
  status = event.payload[:status]
  key = "#{format}.#{controller.underscore.tr('/','_')}_#{action}"
  total = event.duration
  db_time = event.payload[:db_runtime]
  view_time = (event.payload[:view_runtime] || 0)
  Foreman::Telemetry.measure "duration.#{key}.total_duration", total
  Foreman::Telemetry.measure "duration.#{key}.db_time", db_time
  Foreman::Telemetry.measure "duration.#{key}.view_time", view_time
  Foreman::Telemetry.increment "processed.#{key}.#{status}"
  Foreman::Telemetry.measure "duration.total.#{format}.total_duration", total
  Foreman::Telemetry.measure "duration.total.#{format}.db_time", db_time
  Foreman::Telemetry.measure "duration.total.#{format}.view_time", view_time
  Foreman::Telemetry.measure "duration.total_duration.#{status}", total
  Foreman::Telemetry.increment "processed.total.#{status}"
end

ActiveSupport::Notifications.subscribe /instantiation.active_record/ do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  class_name = event.payload[:class_name]
  record_count = event.payload[:record_count]
  Foreman::Telemetry.increment "instantiation.model.#{class_name.underscore.tr('/','_')}", record_count
  Foreman::Telemetry.increment "instantiation.total", record_count
end

ActiveSupport::Notifications.subscribe /deliver.action_mailer/ do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Foreman::Telemetry.increment "mail_delivery.total"
end
