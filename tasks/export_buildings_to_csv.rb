require 'csv'
require_relative '../init'
require_relative '../models/building'
require_relative '../models/housing_violation'

buildings = Building.order(count_overdue_filed_since_pandemic: :desc).limit(100)

ORDERED_FIELDS = [
  :count_overdue_filed_since_pandemic,
  :count_overdue,
  :count_filed_since_pandemic,
  :mean_days_overdue,
  :overdue_mean_days_since_inspection,
  :pre_pandemic_resolved_count,
  :pre_pandemic_mean_resolution_days,
  :count_resolved_during_pandemic,
  :count_resolved_filed_since_pandemic,
  :count_overdue_a,
  :count_overdue_b,
  :count_overdue_c,
  :max_overdue,
  :buildingid,
  :borough,
  :boroid,
  :registrationid,
  :housenumber,
  :lowhousenumber,
  :highhousenumber,
  :streetcode,
  :streetname,
  :postcode,
  :apartment,
  :story,
  :block,
  :lot,
  :bin,
  :bbl,
  :nta,
]

ADDTL_FIELDS = [
  :total_violations,
]

root = "/Users/matty/Documents/Reporting/housing_code_violations/data_processor/data"
CSV.open("#{root}/out.csv", 'w') do |csv|
  csv << (ORDERED_FIELDS + ADDTL_FIELDS)

  buildings.each do |building|
    data = ORDERED_FIELDS.map { |f| building.send f }
    data << HousingViolation.where(buildingid: building.id).count
    csv << data
  end
end
