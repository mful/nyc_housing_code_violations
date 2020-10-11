require 'date'
require 'csv'
require_relative '../init'
require_relative '../models/building'
require_relative '../models/housing_violation'

COLUMNS = [
  'Time period',
  'Filed',
  'Resolved',
  'Mean resolution time',
  'Median resolution time',
  'Resolved overdue',
  'Resolved mean overdue time',
  'Resolved median overdue time',
  'Total overdue',
  'Potentially overdue',
]

IMPORT_DATE = Date.parse '2020-10-02'

def median(violations, a, b)
  vals = violations.map do |v|
    v.send(a) - v.send(b)
  end
  vals.sort!
  len = vals.length
  (vals[(len - 1) / 2] + vals[len / 2]) / 2.0
end

HousingViolation.where(
  'certifieddate IS NOT NULL AND violationstatus = ? AND inspectiondate > ?',
  'Open',
  Date.parse('2020-03-16'),
).count

HousingViolation.where(
  'certifieddate IS NOT NULL AND violationstatus = ? AND inspectiondate < ?',
  'Open',
  Date.parse('2020-01-01'),
).count

def build_row(date, operator)
  row = []
  # filed
  row << HousingViolation.where(
    "inspectiondate #{operator} ?", date).count
  # resolved
  row << HousingViolation.where(
    "inspectiondate #{operator} ? AND (
      certifieddate IS NOT NULL OR violationstatus = ?)",
    date,
    'Close'
  ).count
  # mean resolution time
  row << HousingViolation.where(
    "inspectiondate #{operator} ? AND certifieddate IS NOT NULL",
    date
  ).average("certifieddate - inspectiondate").to_i
  # median resolution time
  row << median(HousingViolation.where(
    "inspectiondate #{operator} ? AND certifieddate IS NOT NULL",
    date
  ), :certifieddate, :inspectiondate)
  # resolved overdue
  row << HousingViolation.where(
    "inspectiondate #{operator} ? AND certifieddate IS NOT NULL AND certifieddate > originalcertifybydate",
    date
  ).count
  # resolved mean overdue time
  row << HousingViolation.where(
    "inspectiondate #{operator} ? AND certifieddate IS NOT NULL AND certifieddate > originalcertifybydate",
    date
  ).average("certifieddate - originalcertifybydate").to_i
  # resolved median overdue time
  row << median(HousingViolation.where(
    "inspectiondate #{operator} ? AND certifieddate IS NOT NULL AND certifieddate > originalcertifybydate",
    date
  ), :certifieddate, :originalcertifybydate)
  # total overdue
  row << HousingViolation.where(
    "inspectiondate #{operator} ? AND (
      (certifieddate IS NOT NULL AND certifieddate > originalcertifybydate)
      OR (certifieddate IS NULL AND violationstatus = ? AND originalcertifybydate < ?))",
    date,
    'Open',
    IMPORT_DATE
  ).count
  # potentially overdue
  row << HousingViolation.where(
    "inspectiondate #{operator} ? AND originalcertifybydate < ?",
    date,
    IMPORT_DATE
  ).count
  row
end

root = "/Users/matty/Documents/Reporting/housing_code_violations/data_processor/data"
CSV.open("#{root}/global.csv", 'w') do |csv|
  csv << COLUMNS
  csv << ['2019'] + build_row(Date.parse('2020-01-01'), '<')
  csv << ['Pandemic'] + build_row(Date.parse('2020-03-16'), '>')
  csv << ['June-Sept'] + build_row(Date.parse('2020-05-31'), '>')
end
