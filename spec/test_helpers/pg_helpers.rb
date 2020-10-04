require 'pg'

module PgHelpers

  def reset_pg_db
    if ENV['APP_ENV'] != 'test'
      raise StandardError.new "STOP: trying to drop tables in a non-test database"
    end

    drop_tables = File.expand_path './assets/drop_tables.sql', File.dirname(__FILE__)
    pg_client.exec File.read(drop_tables)

    setup_db = File.expand_path '../../db.sql', File.dirname(__FILE__)
    pg_client.exec File.read(setup_db)
  end

  private

  def pg_client
    unless @pg_client
      @pg_client = PG.connect(
        dbname: 'housing_code_violations_test',
        host: 'localhost',
        port: '5432',
        user: 'matty',
      )
    end

    @pg_client
  end
end
