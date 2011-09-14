module SpreeCcavenue
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          Time.now.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      def generate_migrations
        migration_template "db/migrate/create_ccavenue_infos.rb", "db/migrate/create_ccavenue_infos.rb" rescue true
      end
    end
  end
end

