# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    Sequel.extension :migration
    Sequel::Migrator.run(DB, 'db/migrations')
    DB[:expenses].truncate
  end
end
