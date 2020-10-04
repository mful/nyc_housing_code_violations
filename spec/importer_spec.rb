require 'byebug'
require 'yaml'
require 'rspec'
require_relative '../init'
require_relative '../importer.rb'
require_relative '../models/building'
require_relative '../models/housing_violation'
require_relative './test_helpers/pg_helpers'

describe Importer do
  include PgHelpers

  before :each do
    reset_pg_db
  end

  describe '#import' do
    let(:violation_fixtures) do
      yml = YAML::load_file(
        File.expand_path './fixtures/violations.yml', File.dirname(__FILE__)
      )
    end
    let(:violation_data) do
      violation_fixtures[:open][:filed_during_pandemic][:overdue]
    end

    context 'for a building that does not yet exist' do
      it 'should import the violation and the building' do
        Importer.new.import(violation_data)
        violation = HousingViolation.first
        building = Building.first
        expected_overdue = Date.today.mjd - Date.strptime(violation_data[:originalcertifybydate], '%m/%d/%Y').mjd
        expected_since_inspection = Date.today.mjd - Date.strptime(violation_data[:inspectiondate], '%m/%d/%Y').mjd
        expect(violation.nil?).to eq(false)
        expect(building.nil?).to eq(false)
        expect(building.count_filed_since_pandemic).to eq(1)
        expect(building.count_resolved_during_pandemic).to eq(0)
        expect(building.count_resolved_filed_since_pandemic).to eq(0)
        expect(building.count_overdue_filed_since_pandemic).to eq(1)
        expect(building.count_overdue).to eq(1)
        expect(building.count_overdue_a).to eq(1)
        expect(building.count_overdue_b).to eq(0)
        expect(building.count_overdue_c).to eq(0)
        expect(building.mean_days_overdue).to eq(expected_overdue)
        expect(building.max_overdue).to eq(expected_overdue)
        expect(building.overdue_mean_days_since_inspection).to eq(expected_since_inspection)
        expect(building.pre_pandemic_resolved_count).to eq(0)
        expect(building.pre_pandemic_mean_resolution_days).to eq(0)
      end
    end

    context 'for a building that already exists' do
      let(:violation_b) do
        violation_fixtures[:open][:filed_during_pandemic][:overdue_same_building]
      end
      let(:violation_c) do
        violation_fixtures[:open][:filed_during_pandemic][:not_overdue]
      end
      let(:violation_d) do
        violation_fixtures[:open][:filed_pre_pandemic][:overdue]
      end
      let(:violation_e) do
        violation_fixtures[:closed][:filed_during_pandemic]
      end
      let(:violation_f) do
        violation_fixtures[:closed][:filed_pre_pandemic]
      end

      before do
        Importer.new.import(violation_data)
      end

      it 'should update the averages appropriately' do
        i = Importer.new
        i.import violation_b
        i.import violation_c
        i.import violation_d
        i.import violation_e
        i.import violation_f

        td = Date.today.mjd
        a_days_overdue = td - Date.strptime(violation_data[:originalcertifybydate], '%m/%d/%Y').mjd
        b_days_overdue = td - Date.strptime(violation_b[:originalcertifybydate], '%m/%d/%Y').mjd
        d_days_overdue = td - Date.strptime(violation_d[:originalcertifybydate], '%m/%d/%Y').mjd
        expected_overdue = (a_days_overdue + b_days_overdue + d_days_overdue) / 3

        a_days_inspect = td - Date.strptime(violation_data[:inspectiondate], '%m/%d/%Y').mjd
        b_days_inspect = td - Date.strptime(violation_b[:inspectiondate], '%m/%d/%Y').mjd
        d_days_inspect = td - Date.strptime(violation_d[:inspectiondate], '%m/%d/%Y').mjd
        expected_since_inspection = (a_days_inspect + b_days_inspect + d_days_inspect) / 3

        expected_pre_res =
          Date.strptime(violation_f[:certifieddate], '%m/%d/%Y').mjd -
          Date.strptime(violation_f[:inspectiondate], '%m/%d/%Y').mjd

        expect(Building.count).to eq(1)
        expect(HousingViolation.count).to eq(6)

        building = Building.first
        expect(building.count_filed_since_pandemic).to eq(4)
        expect(building.count_resolved_during_pandemic).to eq(1)
        expect(building.count_resolved_filed_since_pandemic).to eq(1)
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
      end
    end
  end
end
