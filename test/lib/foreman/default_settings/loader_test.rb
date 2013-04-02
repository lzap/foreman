require 'test_helper'
require 'puppet_setting'
require 'foreman/default_settings/loader'

class DefaultSettingsLoaderTest < ActiveSupport::TestCase
  # Check one of the puppetmaster sourced settings was loaded
  test "should initialize hostcert from Puppet" do
    PuppetSetting.any_instance.stubs(:get).returns({:hostcert => '/var/lib/puppet/mycert.pem'})
    Foreman::DefaultSettings::Loader.load
    assert_equal '/var/lib/puppet/mycert.pem', Setting.find_by_name('ssl_certificate').value
  end

  test "should disable param class ENC support on Puppet < 2.6.5" do
    PuppetSetting.any_instance.stubs(:get).returns({})
    Facter.expects(:puppetversion).returns('2.6.4')
    Foreman::DefaultSettings::Loader.load
    assert_equal false, Setting.find_by_name('Parametrized_Classes_in_ENC').value
  end

  test "should enable param class ENC support on Puppet >= 2.6.5" do
    PuppetSetting.any_instance.stubs(:get).returns({})
    Facter.expects(:puppetversion).returns('2.6.5')
    Foreman::DefaultSettings::Loader.load
    assert Setting.find_by_name('Parametrized_Classes_in_ENC').value
  end

  test "should handle -rc version numbers" do
    PuppetSetting.any_instance.stubs(:get).returns({})
    Facter.expects(:puppetversion).returns('3.0.2-rc1')
    Foreman::DefaultSettings::Loader.load
    assert_equal true, Setting.find_by_name('Parametrized_Classes_in_ENC').value
  end

  test "should store boolean, not string for using_storeconfigs" do
    PuppetSetting.any_instance.stubs(:get).returns({:storeconfigs => 'true'})
    Foreman::DefaultSettings::Loader.load
    assert_equal TrueClass, Setting.where(:name => :using_storeconfigs).first.default.class
  end
end

