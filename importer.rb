require 'byebug'
require 'date'
require_relative './models/building'
require_relative './models/housing_violation'

class Importer
  PANDEMIC_START_DATE = Date.parse '2020-03-17'
  DATE_FIELDS = [
    :inspectiondate,
    :approveddate,
    :originalcertifybydate,
    :originalcorrectbydate,
    :newcertifybydate,
    :newcorrectbydate,
    :certifieddate,
    :novissueddate,
    :currentstatusdate,
  ]
  CHAR_1_FIELDS = [
    :violation_class,
  ]
  CHAR_50_FIELDS = [
    :borough,
    :housenumber,
    :lowhousenumber,
    :highhousenumber,
    :apartment,
    :story,
  ]
  CHAR_100_FIELDS = [
    :postcode,
  ]
  CHAR_255_FIELDS = [
    :streetname,
    :streetcode,
    :ordernumber,
    :violationstatus,
    :latitude,
    :longitude,
    :councildistrict,
    :censustract,
    :bin,
    :bbl,
    :nta,
  ]
  CHAR_FIELDS = [
    [CHAR_1_FIELDS, 1],
    [CHAR_50_FIELDS, 50],
    [CHAR_100_FIELDS, 100],
    [CHAR_100_FIELDS, 255],
  ]
  INT_FIELDS = [
    :violationid,
    :buildingid,
    :registrationid,
    :boroid,
    :block,
    :lot,
    :novid,
    :currentstatusid,
  ]

  def initialize
  end

  def import(violation_data)
    data = normalize_violation violation_data
    violation = import_violation data
    import_building violation, data
  end

  def import_building(violation, violation_data = {})
    building = Building.where(buildingid: violation.buildingid).first

    unless building
      # create it
      building = Building.create(
        violation_data.slice(
          :buildingid,
          :boro,
          :boroid,
          :registrationid,
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
          :bin,
          :bbl,
          :nta,
        )
      )
    end

    updates = {
      count_filed_since_pandemic: building.count_filed_since_pandemic,
      count_resolved_during_pandemic: building.count_resolved_during_pandemic,
      count_resolved_filed_since_pandemic: building.count_resolved_filed_since_pandemic,
      count_overdue_filed_since_pandemic: building.count_overdue_filed_since_pandemic,
      count_overdue: building.count_overdue,
      count_overdue_a: building.count_overdue_a,
      count_overdue_b: building.count_overdue_b,
      count_overdue_c: building.count_overdue_c,
      mean_days_overdue: building.mean_days_overdue,
      max_overdue: building.max_overdue,
      overdue_mean_days_since_inspection: building.overdue_mean_days_since_inspection,
      pre_pandemic_resolved_count: building.pre_pandemic_resolved_count,
      pre_pandemic_mean_resolution_days: building.pre_pandemic_mean_resolution_days,
    }

    update_building_stats building, violation, updates
  end

  def import_violation(violation_data)
    HousingViolation.find(
      HousingViolation.upsert(violation_data).first['violationid']
    )
  end

  def update_building_stats(building, violation, updates)
    if violation.inspectiondate >= PANDEMIC_START_DATE
      updates[:count_filed_since_pandemic] += 1
    end

    if violation.violationstatus == 'Close'
      if violation.certifieddate
        if violation.certifieddate >= PANDEMIC_START_DATE
          updates[:count_resolved_during_pandemic] += 1

          if violation.inspectiondate && violation.inspectiondate >= PANDEMIC_START_DATE
            updates[:count_resolved_filed_since_pandemic] += 1
          end

        elsif violation.inspectiondate && violation.inspectiondate < PANDEMIC_START_DATE
          res_days = violation.certifieddate - violation.inspectiondate
          tot_res_days =
            building.pre_pandemic_mean_resolution_days * building.pre_pandemic_resolved_count
          new_mean = (tot_res_days + res_days) / (building.pre_pandemic_resolved_count + 1)

          updates[:pre_pandemic_resolved_count] += 1
          updates[:pre_pandemic_mean_resolution_days] = new_mean
        end
      end

    elsif violation.originalcertifybydate && violation.originalcertifybydate < Date.today
      days_overdue = Date.today.mjd - violation.originalcertifybydate.mjd
      tot_days_overdue =
        building.mean_days_overdue * building.count_overdue + days_overdue

      days_since_inspection = Date.today.mjd - violation.inspectiondate.mjd
      tot_since_inspection =
        building.overdue_mean_days_since_inspection * building.count_overdue + days_since_inspection

      updates[:mean_days_overdue] =
        tot_days_overdue / (building.count_overdue + 1)
      updates[:overdue_mean_days_since_inspection] =
        tot_since_inspection / (building.count_overdue + 1)

      if days_overdue > updates[:max_overdue]
        updates[:max_overdue] = days_overdue
      end

      updates[:count_overdue] += 1
      if violation.inspectiondate >= PANDEMIC_START_DATE
        updates[:count_overdue_filed_since_pandemic] += 1
      end

      case violation.violation_class
      when 'A'
        updates[:count_overdue_a] += 1
      when 'B'
        updates[:count_overdue_b] += 1
      when 'C'
        updates[:count_overdue_c] += 1
      end
    end

    building.update updates
  end

  private

  def normalize_violation(raw_data)
    data = raw_data.clone
    data[:violation_class] = data[:class]
    data.delete :class

    DATE_FIELDS.each do |field|
      data[field] = data[field].strip if data[field].is_a?(String)

      if data[field].nil? || data[field] == ''
        data[field] = nil
      elsif data[field].match(/\d{2}\/\d{2}\/\d{4}/)
        data[field] = Date.strptime(data[field], "%m/%d/%Y")
      else
        begin
          data[field] = Date.parse(data[field][0..9])
        rescue StandardError => e
          puts "failed to set #{field} on violation #{data[:violationid]} for raw value #{data[:field]}"
        end
      end
    end

    CHAR_FIELDS.each do |field_limits|
      limit = field_limits[1]

      field_limits[0].each do |field|
        data[field] = data[field].strip if data[field].is_a?(String)
        if data[field].nil? || data[field] == ''
          data[field] = nil
        else
          data[field] = data[field][0...limit]
        end
      end
    end

    INT_FIELDS.each do |field|
      data[field] = data[field].strip if data[field].is_a?(String)
      if data[field].nil? || data[field] == ''
        data[field] = nil
      else
        data[field] = data[field].to_i
      end
    end

    data
  end
end
