require 'csv'
require_relative '../init'
require_relative '../models/building'
require_relative '../models/housing_violation'

buildings = Building.connection.execute(%Q{
  SELECT *,
    (CAST(pre_pandemic_resolved_count AS DOUBLE PRECISION) / CAST((
    (SELECT COUNT(*) FROM housing_violations
     WHERE housing_violations.buildingid = buildings.buildingid
    ) - count_filed_since_pandemic) AS DOUBLE PRECISION)
    ) AS percent_pre_resolved,
    (CAST(count_resolved_filed_since_pandemic AS DOUBLE PRECISION) / CAST(
      count_filed_since_pandemic AS DOUBLE PRECISION)
    ) AS percent_resolved_during,
    (
      (CAST(pre_pandemic_resolved_count AS DOUBLE PRECISION) / CAST((
        (SELECT COUNT(*) FROM housing_violations
          WHERE housing_violations.buildingid = buildings.buildingid
        ) - count_filed_since_pandemic) AS DOUBLE PRECISION)
      ) -
      (
        CAST(count_resolved_filed_since_pandemic AS DOUBLE PRECISION) / CAST(
          count_filed_since_pandemic AS DOUBLE PRECISION)
      )
    ) AS fix_diff
  FROM buildings
  WHERE count_filed_since_pandemic != (
    SELECT COUNT(*) FROM housing_violations
    WHERE housing_violations.buildingid = buildings.buildingid
  )
  AND count_overdue_filed_since_pandemic > 25
  AND pre_pandemic_mean_resolution_days < 35
  AND pre_pandemic_resolved_count > 10
  ORDER BY fix_diff DESC
  LIMIT 100
})


ORDERED_FIELDS = [
  'fix_diff',
  'percent_pre_resolved',
  'percent_resolved_during',
  'count_overdue_filed_since_pandemic',
  'count_overdue',
  'count_filed_since_pandemic',
  'mean_days_overdue',
  'overdue_mean_days_since_inspection',
  'pre_pandemic_resolved_count',
  'pre_pandemic_mean_resolution_days',
  'count_resolved_during_pandemic',
  'count_resolved_filed_since_pandemic',
  'count_overdue_a',
  'count_overdue_b',
  'count_overdue_c',
  'max_overdue',
  'buildingid',
  'borough',
  'boroid',
  'registrationid',
  'housenumber',
  'lowhousenumber',
  'highhousenumber',
  'streetcode',
  'streetname',
  'postcode',
  'block',
  'lot',
  'bin',
  'bbl',
  'nta',
]

root = "/Users/matty/Documents/Reporting/housing_code_violations/data_processor/data"
CSV.open("#{root}/out-#{Time.now.strftime("%Y-%m-%d-%H-%M")}.csv", 'w') do |csv|
  csv << (['total_violations'] + ORDERED_FIELDS)

  buildings.each do |building|
    data = ORDERED_FIELDS.map { |f| building[f] }
    data.unshift HousingViolation.where(buildingid: building['buildingid']).count
    csv << data
  end
end
