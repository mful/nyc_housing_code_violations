require 'byebug'
require 'yaml'
require 'rspec'
require_relative '../../init'
require_relative '../../importer'
require_relative '../../models/building'
require_relative '../../models/housing_violation'
require_relative '../../services/recalculate_building_stats'
require_relative '../test_helpers/pg_helpers'

describe RecalculateBuildingStats do
  include PgHelpers

  let(:violation_fixtures) do
    yml = YAML::load_file(
      File.expand_path '../fixtures/violations.yml', File.dirname(__FILE__)
    )
  end

  before :each do
    reset_pg_db
  end

  describe '#recalculate' do
    before :each do
      importer = Importer.new
      @a = importer.import_violation violation_fixtures[:open][:filed_during_pandemic][:overdue]
      @b = importer.import_violation violation_fixtures[:open][:filed_during_pandemic][:overdue_same_building]
      @c = importer.import_violation violation_fixtures[:open][:filed_during_pandemic][:not_overdue]
      @d = importer.import_violation violation_fixtures[:open][:filed_pre_pandemic][:overdue]
      @e = importer.import_violation violation_fixtures[:closed][:filed_during_pandemic]
      @f = importer.import_violation violation_fixtures[:closed][:filed_pre_pandemic]
      Building.create(violation_fixtures[:open][:filed_during_pandemic][:overdue].slice(
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
      ))
    end

    it 'should set the expected stats' do
      building = Building.first

      td = RecalculateBuildingStats::IMPORT_DATE.mjd
      a_days_overdue = td - @a.originalcertifybydate.mjd
      b_days_overdue = @b.certifieddate.mjd - @b.originalcertifybydate.mjd
      d_days_overdue = td - @d.originalcertifybydate.mjd
      expected_overdue = (a_days_overdue + b_days_overdue + d_days_overdue) / 3

      a_days_inspect = td - @a.inspectiondate.mjd
      b_days_inspect = td - @b.inspectiondate.mjd
      d_days_inspect = td - @d.inspectiondate.mjd
      expected_since_inspection = (a_days_inspect + b_days_inspect + d_days_inspect) / 3

      expected_pre_res = @f.certifieddate.mjd - @f.inspectiondate.mjd

      RecalculateBuildingStats.new.recalculate building
      building.reload

      expect(building.count_filed_since_pandemic).to eq(4)
      expect(building.count_resolved_during_pandemic).to eq(2)
      expect(building.count_resolved_filed_since_pandemic).to eq(2)
      expect(building.count_overdue_filed_since_pandemic).to eq(2)
      expect(building.count_overdue).to eq(3)
      expect(building.count_overdue_a).to eq(1)
      expect(building.count_overdue_b).to eq(0)
      expect(building.count_overdue_c).to eq(2)
      expect(building.mean_days_overdue).to eq(expected_overdue)
      expect(building.max_overdue).to eq(d_days_overdue)
      expect(building.overdue_mean_days_since_inspection).to eq(expected_since_inspection)
      expect(building.pre_pandemic_resolved_count).to eq(1)
      expect(building.pre_pandemic_mean_resolution_days).to eq(expected_pre_res)
      expect(building.overdue_pre_pandemic_rate).to eq(1.0 / 2)
      expect(building.overdue_since_pandemic_rate).to eq(2.0 / 3)
    end
  end
end
