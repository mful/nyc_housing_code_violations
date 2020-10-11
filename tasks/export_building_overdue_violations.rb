require 'csv'
require_relative '../init'
require_relative '../models/building'
require_relative '../models/housing_violation'

buildingid = ARGV[0]

unless buildingid
  puts "Must provide a buildingid"
  exit 1
end

building = Building.find(buildingid)
violations = HousingViolation.where(
  buildingid: buildingid,
  violationstatus: 'Open',
).where(
  "originalcertifybydate < ? and currentstatus NOT IN (?)",
  Date.today,
  ["CIV14 MAILED", "VIOLATION WILL BE REINSPECTED"]
)

ORDERED_FIELDS = [
  :certifieddate,
  :violation_class,
  :novid,
  :novdescription,
  :inspectiondate,
  :originalcertifybydate,
  :newcertifybydate,
  :apartment,
  :story,
  :approveddate,
  :originalcorrectbydate,
  :newcorrectbydate,
  :ordernumber,
  :novissueddate,
  :currentstatusid,
  :currentstatus,
  :currentstatusdate,
  :novtype,
  :violationstatus,
  :violationid,
]

root = "/Users/matty/Documents/Reporting/housing_code_violations/data_processor/data"
filename = "violations-#{building.housenumber}-#{building.streetname}-#{building.boroid}.csv"
CSV.open("#{root}/#{filename}", 'w') do |csv|
  csv << ORDERED_FIELDS

  violations.find_each do |violation|
    csv << ORDERED_FIELDS.map { |f| violation.send f }
  end
end
