require_relative '../init'
require_relative '../models/building'
require_relative '../models/housing_violation'

class RecalculateBuildingStats
  PANDEMIC_START_DATE = Date.parse '2020-03-17'
  IMPORT_DATE = Date.parse '2020-10-02'

  def initialize
  end

  def recalculate(building)
    violations_since_pan = HousingViolation.where(
      buildingid: building.buildingid).where('inspectiondate >= ?', PANDEMIC_START_DATE)
    violations_pre_pan = HousingViolation.where(
      buildingid: building.buildingid).where('inspectiondate < ?', PANDEMIC_START_DATE)
    violations = HousingViolation.where(buildingid: building.buildingid)

    over_stats = overdue_stats(violations)

    building.update(
      count_filed_since_pandemic: violations_since_pan.count,
      count_resolved_during_pandemic: count_resolved_during_pandemic(violations),
      count_resolved_filed_since_pandemic: count_resolved(violations_since_pan),
      count_overdue_filed_since_pandemic: count_overdue(violations_since_pan),
      count_overdue: count_overdue(violations),
      count_overdue_a: count_overdue(violations.where(violation_class: 'A')),
      count_overdue_b: count_overdue(violations.where(violation_class: 'B')),
      count_overdue_c: count_overdue(violations.where(violation_class: 'C')),
      mean_days_overdue: over_stats[:mean_overdue],
      max_overdue: over_stats[:max],
      overdue_mean_days_since_inspection: over_stats[:mean_since_inspection],
      pre_pandemic_resolved_count:
        count_resolved_pre_pandemic(violations_pre_pan),
      pre_pandemic_mean_resolution_days:
        mean_resolution_days(violations_pre_pan),
      overdue_pre_pandemic_rate: overdue_rate(violations_pre_pan),
      overdue_since_pandemic_rate: overdue_rate(violations_since_pan)
    )
  end

  private

  def count_overdue(violations)
    overdue(violations).count
  end

  def count_resolved(violations)
    resolved(violations).count
  end

  def count_resolved_during_pandemic(violations)
    count_resolved(violations.where(
      'certifieddate IS NOT NULL AND certifieddate >= ?',
      PANDEMIC_START_DATE,
    ))
  end

  def count_resolved_pre_pandemic(violations)
    count_resolved(violations.where(
      'certifieddate IS NOT NULL AND certifieddate < ?',
      PANDEMIC_START_DATE,
    ))
  end

  def mean_resolution_days(violations)
    sum = 0
    count = 0

    resolved(violations).where('certifieddate IS NOT NULL').each do |violation|
      count += 1
      sum += violation.certifieddate - violation.inspectiondate
    end

    count == 0 ? 0 : sum.to_f / count.to_f
  end

  def overdue_stats(violations)
    count = 0.0
    today = IMPORT_DATE.mjd
    max = 0
    overdue_days = 0
    since_inspection = 0

    overdue(violations).each do |violation|
      if violation.certifieddate
        days_over = violation.certifieddate.mjd - violation.originalcertifybydate.mjd
      else
        days_over =  today - violation.originalcertifybydate.mjd
      end

      count += 1
      overdue_days += days_over
      since_inspection += (today - violation.inspectiondate.mjd)
      max = [max, days_over].max
    end

    count == 0 ? { max: 0, mean_overdue: 0, mean_since_inspection: 0 } :
    {
      max: max,
      mean_overdue: overdue_days.to_f / count,
      mean_since_inspection: since_inspection.to_f / count,
    }
  end

  def overdue(violations)
    violations.where(
      '(certifieddate IS NOT NULL AND certifieddate > originalcertifybydate)
      OR (certifieddate IS NULL AND violationstatus = ?
        AND originalcertifybydate < ?)',
      'Open',
      IMPORT_DATE
    )
  end

  def overdue_rate(violations)
    potential = violations.where('originalcertifybydate < ?', IMPORT_DATE).count
    actual = overdue(violations).count

    potential == 0 ? 0 : actual.to_f / potential.to_f
  end

  def resolved(violations)
    violations.where(
      'certifieddate IS NOT NULL OR violationstatus = ?',
      'Close'
    )
  end
end
