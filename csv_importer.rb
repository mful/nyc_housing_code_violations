require 'csv'
require_relative './importer'


class CSVImporter
  KEYS = [
    :violationid,
    :buildingid,
    :registrationid,
    :boroid,
    :borough,
    :housenumber,
    :lowhousenumber,
    :highhousenumber,
    :streetname,
    :streetcode,
    :postcode,
    :apartment,
    :story,
    :block,
    :lot,
    :class,
    :inspectiondate,
    :approveddate,
    :originalcertifybydate,
    :originalcorrectbydate,
    :newcertifybydate,
    :newcorrectbydate,
    :certifieddate,
    :ordernumber,
    :novid,
    :novdescription,
    :novissueddate,
    :currentstatusid,
    :currentstatus,
    :currentstatusdate,
    :novtype,
    :violationstatus,
    :latitude,
    :longitude,
    :communityboard,
    :councildistrict,
    :censustract,
    :bin,
    :bbl,
    :nta
  ]

  def initialize(path, min_inspection_date)
    @path = path
    @min_inspection_date = Date.parse(min_inspection_date)
    @importer = Importer.new
  end

  def import
    count = 0
    imported_count = 0
    CSV.foreach(@path) do |row|
      count += 1
      next if count == 1 # skip header row

      data = KEYS.zip(row).to_h
      if Date.strptime(data[:inspectiondate], "%m/%d/%Y") >= @min_inspection_date
        @importer.import data
        imported_count += 1
      end

      if count % 10000 == 0
        puts "processed: #{count}  |  imported: #{imported_count}"
      end
    end
  end
end
