require 'test_helper'

class ConfigReportTest < ActiveSupport::TestCase
  def setup
    User.current = users :admin
  end

  let (:report_skipped) { ConfigReport.import read_json_fixture("reports/skipped.json") }
  let (:report_empty) { ConfigReport.import read_json_fixture("reports/empty.json") }

  test "it contains some logs" do
    assert_equal([["err", "Could not retrieve catalog from remote server: Error 400 on SERVER: Could not find node 'rhel6n01.corp.com'; cannot compile", "Puppet"], ["notice", "Using cached catalog", "Puppet"], ["err", "Could not retrieve catalog; skipping run", "Puppet"]], report_empty.logs)
  end

  test "it should true on error? if there were errors" do
    report_skipped.status = {"applied" => 92, "restarted" => 300, "failed" => 4, "failed_restarts" => 12, "skipped" => 3, "pending" => 0}
    assert report_skipped.error?
  end

  test "it should not be an error if there are only skips" do
    report_skipped.status = {"applied" => 92, "restarted" => 300, "failed" => 0, "failed_restarts" => 0, "skipped" => 3, "pending" => 0}
    assert !report_skipped.error?
  end

  test "it should false on error? if there were no errors" do
    report_skipped.status = {"applied" => 92, "restarted" => 300, "failed" => 0, "failed_restarts" => 0, "skipped" => 0, "pending" => 0}
    assert !report_skipped.error?
  end

  test "with named scope should return our report with applied resources" do
    report_skipped.status = {"applied" => 15, "restarted" => 0, "failed" => 0, "failed_restarts" => 0, "skipped" => 0, "pending" => 0}
    report_skipped.save
    assert ConfigReport.with("applied", 14).include?(report_skipped)
    assert !ConfigReport.with("applied", 15).include?(report_skipped)
  end

  test "with named scope should return our report with restarted resources" do
    report_skipped.status = {"applied" => 0, "restarted" => 5, "failed" => 0, "failed_restarts" => 0, "skipped" => 0, "pending" => 0}
    report_skipped.save
    assert ConfigReport.with("restarted").include?(report_skipped)
  end

  test "with named scope should return our report with failed resources" do
    report_skipped.status = {"applied" => 0, "restarted" => 0, "failed" => 9, "failed_restarts" => 0, "skipped" => 0, "pending" => 0}
    report_skipped.save
    assert ConfigReport.with("failed").include?(report_skipped)
  end

  test "with named scope should return our report with failed_restarts resources" do
    report_skipped.status = {"applied" => 0, "restarted" => 0, "failed" => 0, "failed_restarts" => 91, "skipped" => 0, "pending" => 0}
    report_skipped.save
    assert ConfigReport.with("failed_restarts").include?(report_skipped)
  end

  test "with named scope should return our report with skipped resources" do
    report_skipped.status = {"applied" => 0, "restarted" => 0, "failed" => 0, "failed_restarts" => 0, "skipped" => 8, "pending" => 0}
    report_skipped.save
    assert ConfigReport.with("skipped").include?(report_skipped)
  end

  test "with named scope should return our report with skipped resources when other bits are also used" do
    report_skipped.status = {"applied" => 0, "restarted" => 0, "failed" => 9, "failed_restarts" => 4, "skipped" => 8, "pending" => 3}
    report_skipped.save
    assert ConfigReport.with("skipped").include?(report_skipped)
  end

  test "with named scope should return our report with pending resources when other bits are also used" do
    report_skipped.status = {"applied" => 0, "restarted" => 0, "failed" => 9, "failed_restarts" => 4, "skipped" => 8, "pending" => 3}
    report_skipped.save
    assert ConfigReport.with("pending").include?(report_skipped)
  end
end
