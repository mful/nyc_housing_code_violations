require 'active_record'
require_relative '../init'

class HousingViolation < ActiveRecord::Base
  self.primary_key = 'violationid'
end
