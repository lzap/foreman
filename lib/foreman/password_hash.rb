require 'active_support/core_ext/module/delegation'

#
# Generic-purpose password hasher with two implementations: BCrypt and SHA1.
#
# generate_salt(cost) - generates random salt of optional cost (1-30)
# calculate_salt(object, cost) - calculates hash from given object (useful for tokens)
# hash_secret(password, salt) - returns hash from secret and salt
#
module Foreman
  class PasswordHash
    class PBKDF2Implementation
      SIZE = 39
      ITERATIONS = 4096

      def generate_salt(size = SIZE, cost = ITERATIONS)
        "$pbkdf2sha1$#{cost}$#{SecureRandom.base64(size)}"
      end

      def calculate_salt(object, cost = ITERATIONS)
        "$pbkdf2sha1$#{cost}$#{Digest::SHA1.hexdigest(object.to_s)}"
      end

      def hash_secret(password, salt)
        raise(Foreman::Exception.new(N_("Salt not in format of $pbkdf2sha1$ITERATIONS$SALT: %s"), salt)) unless salt.start_with?('$pbkdf2sha1')
        _p1, _p2, iters, clean_salt = salt.split('$', 4)
        hash = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, clean_salt, iters.to_i, SIZE)
        "#{salt}$#{Base64.strict_encode64(hash)}"
      end
    end

    class BCryptImplementation
      def generate_salt(cost = Setting[:bcrypt_cost])
        BCrypt::Engine.generate_salt(cost)
      end

      def calculate_salt(object, cost = Setting[:bcrypt_cost])
        "$2a$#{cost.to_s.rjust(2, '0')}$#{Digest::SHA1.hexdigest(object.to_s)}"
      end

      def hash_secret(password, salt)
        BCrypt::Engine.hash_secret(password, salt)
      rescue BCrypt::Errors::InvalidSalt
        # bcrypt expects '$2a$nn$minimum22characters'
        raise(Foreman::Exception.new(N_("BCrypt salt '%s' is invalid"), salt))
      end
    end

    class SHA1Implementation
      def generate_salt(_cost = nil)
        Digest::SHA1.hexdigest([Time.now.utc, rand].join)
      end

      def calculate_salt(object, _cost = nil)
        Digest::SHA1.hexdigest(object.to_s)
      end

      def hash_secret(password, salt)
        Digest::SHA1.hexdigest([password, salt].join)
      end
    end

    def initialize(implementation = Setting[:password_hash])
      case implementation.to_sym
      when :pbkdf2sha1
        @implementation = PBKDF2Implementation.new
      when :bcrypt
        @implementation = BCryptImplementation.new
      when :sha1
        @implementation = SHA1Implementation.new
      else
        raise(Foreman::Exception.new(N_("Unknown password hash method: %s"), implementation))
      end
    end

    def self.detect_implementation(password_string)
      return :pbkdf2sha1 if password_string.start_with?('$pbkdf2sha1')
      return :bcrypt if password_string.start_with?('$2')
      :sha1
    end

    delegate :generate_salt, :calculate_salt, :hash_secret, to: :implementation

    private

    attr_reader :implementation
  end
end
