require_relative '../init'
require_relative '../models/building'
require_relative '../services/recalculate_building_stats'

updater = RecalculateBuildingStats.new
count = 0
Building.find_each do |building|
  updater.recalculate building
  count += 1

  if count % 1000 == 0
    puts "processed #{count} buildings..."
  end
end
