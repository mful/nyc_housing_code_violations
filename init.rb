require 'active_record'

db = ENV['APP_ENV'] == 'test' ? 'housing_code_violations_test' : 'housing_code_violations'
ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  username: 'matty',
  database: db,
)
