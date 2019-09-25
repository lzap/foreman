require 'benchmark/ips'

def make_report(host = 1, logs = 100)
  base = {
    "host" => "host#{host}.example.com", "reported_at" => Time.now.utc.to_s,
    "status" => { "applied" => 0, "restarted" => 0, "failed" => 1, "failed_restarts" => 0, "skipped" => 0, "pending" => 0 },
    "metrics" => { "time" => { "config_retrieval" => 6.98906397819519, "total" => 13.8197405338287 }, "resources" => { "applied" => 0, "failed" => 1, "failed_restarts" => 0, "out_of_sync" => 0, "restarted" => 0, "scheduled" => 67, "skipped" => 0, "total" => 68 }, "changes" => { "total" => 0 } },
    "logs" => [],
  }
  (1..logs).each do |i|
    base["logs"].append({
      "log" => { "sources" => { "source" => "//Node[#{i}]/my_servers/minimal/time/Service[#{i}]" },
      "messages" => { "message" => "Failed to retrieve current state of resource: #{i}" },
      "level" => "err" }
    })
    base["logs"].append({
      "log" => { "sources" => { "source" => "Puppet" },
      "messages" => { "message" => "Using cached catalog" },
      "level" => "notice" }
    })
  end
  base
end

Rails.logger.level = Logger::ERROR

ConfigReport.import(make_report(1, 5))
ConfigReport.last

###################

Benchmark.ips do |x|
  host_id = 1
  x.config(:time => 30 * 60, :warmup => 0)
  x.report("import report 50/50") do
    report = make_report(host_id, 100)
    ConfigReport.import(report)
    host_id += 1
  end
end

###################

ConfigReport.destroy_all
