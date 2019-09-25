module Foreman
  # Rails model serializer that does nothing on save (let DB driver to do the work)
  # but on load it converts the hash to indifferent access.
  class IndifferentAccessDeserializer < HashWithIndifferentAccess
    # do nothing on save
    def self.dump(obj)
      obj
    end
  
    # convert to indifferent access on load
    def self.load(raw_hash)
      new(raw_hash || {}) 
    end
  end
end