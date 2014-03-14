module Gitlab
  module LDAP
    class Access
      attr_reader :adapter

      def self.open(&block)
        Gitlab::LDAP::Adapter.open do |adapter|
          block.call(self.new(adapter))
        end
      end

      def initialize(adapter=nil)
        @adapter = adapter
      end

      def allowed?(user)
        !!Gitlab::LDAP::Person.find_by_dn(user.extern_uid, adapter)
      rescue
        false
      end
    end
  end
end
