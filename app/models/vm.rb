module Vm
  PROPERTIES = [ :hypervisor_id, :storage_pool, :interface, :memory, :vcpu, :disk_size, :network_type ]

  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      Vm::PROPERTIES.each {|a| attr_accessor(a)}
      validates_presence_of :memory, :vcpu, :storage_pool, :disk_size, :network_type, :interface, :if => Proc.new{|h| h.hypervisor?}
    end
  end

  module InstanceMethods
    def hypervisor?
      !hypervisor_id.blank?
    end

    def hypervisor
      return nil unless hypervisor?
      Hypervisor.find(hypervisor_id)
    rescue ActiveRecord::RecordNotFound
      # we stored an invalid hypervisor
      self.hypervisor_id = nil
    end

  end

end
