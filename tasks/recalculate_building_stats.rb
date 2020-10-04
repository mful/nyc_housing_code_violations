require_relative '../init'
require_relative '../importer'
require_relative '../models/building'
require_relative '../models/housing_violation'

IMPORTER = Importer.new
UPDATES = {
  count_filed_since_pandemic: 0,
  count_resolved_during_pandemic: 0,
  count_resolved_filed_since_pandemic: 0,
  count_overdue_filed_since_pandemic: 0,
  count_overdue: 0,
  count_overdue_a: 0,
  count_overdue_b: 0,
  count_overdue_c: 0,
  mean_days_overdue: 0,
  max_overdue: 0,
  overdue_mean_days_since_inspection: 0,
  pre_pandemic_resolved_count: 0,
  pre_pandemic_mean_resolution_days: 0,
}

Building.find_each do |building|
  updates = UPDATES.clone
  HousingViolation.where(buildingid: building.buildingid).find_each do |hv|
    IMPORTER.update_building_stats building, hv, updates
  end
end
