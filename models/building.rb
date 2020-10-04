require 'active_record'
require_relative '../init'

class Building < ActiveRecord::Base
  self.primary_key = 'buildingid'
end
