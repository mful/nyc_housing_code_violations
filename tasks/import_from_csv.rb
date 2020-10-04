require_relative '../init'
require_relative '../csv_importer'

importer = CSVImporter.new(
  "/Users/matty/Documents/Reporting/housing_code_violations/data_processor/data/Housing_Maintenance_Code_Violations.csv",
  "2019-01-01",
)

importer.import
