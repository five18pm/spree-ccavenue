module SpreeCcavenue
  module Generators
    class UpgradeGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      def self.source_root
        @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      end

      def self.next_migration_number(path)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end

      def add_upgrade_migration
        migration_template "upgrade_ccavenue_tables.rb", "db/migrate/upgrade_ccavenue_tables.rb"
      end
    end
  end
end