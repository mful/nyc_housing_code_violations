CREATE table IF NOT EXISTS housing_violations (
  violationid            integer PRIMARY KEY NOT NULL,
  buildingid             integer,
  registrationid         integer,
  boroid                 integer,
  borough                varchar(50),
  housenumber            varchar(50),
  lowhousenumber         varchar(50),
  highhousenumber        varchar(50),
  streetname             varchar(255),
  streetcode             varchar(255),
  postcode               varchar(100),
  apartment              varchar(50),
  story                  varchar(50),
  "block"                integer,
  lot                    integer,
  violation_class        varchar(1),
  inspectiondate         date,
  approveddate           date,
  originalcertifybydate  date,
  originalcorrectbydate  date,
  newcertifybydate       date,
  newcorrectbydate       date,
  certifieddate          date,
  ordernumber            varchar(255),
  novid                  integer,
  novdescription         text,
  novissueddate          date,
  currentstatusid        integer,
  currentstatus          text,
  currentstatusdate      date,
  novtype                text,
  violationstatus        varchar(255),
  latitude               varchar(255),
  longitude              varchar(255),
  communityboard         text,
  councildistrict        varchar(255),
  censustract            varchar(255),
  bin                    varchar(255),
  bbl                    varchar(255),
  nta                    varchar(255),
  updated_at             timestamp default current_timestamp
);

CREATE INDEX IF NOT EXISTS violations_buildingid_idx ON housing_violations (buildingid);
CREATE INDEX IF NOT EXISTS violations_violationstatus_idx ON housing_violations (violationstatus);
CREATE INDEX IF NOT EXISTS violations_boroid_idx ON housing_violations (boroid);
CREATE INDEX IF NOT EXISTS violations_originalcertifybydate_idx ON housing_violations (originalcertifybydate);
CREATE INDEX IF NOT EXISTS violations_originalcorrectbydate_idx ON housing_violations (originalcorrectbydate);
CREATE INDEX IF NOT EXISTS violations_certifieddate_idx ON housing_violations (certifieddate);

CREATE TABLE IF NOT EXISTS buildings (
  buildingid                            integer PRIMARY KEY NOT NULL,
  borough                               varchar(50),
  boroid                                integer,
  registrationid                        integer,
  housenumber                           varchar(50),
  lowhousenumber                        varchar(50),
  highhousenumber                       varchar(50),
  streetcode                            varchar(255),
  streetname                            varchar(255),
  postcode                              varchar(100),
  apartment                             varchar(50),
  story                                 varchar(50),
  "block"                               integer,
  lot                                   integer,
  bin                                   varchar(255),
  bbl                                   varchar(255),
  nta                                   varchar(255),
  count_filed_since_pandemic            integer DEFAULT 0 NOT NULL,
  count_resolved_during_pandemic        integer DEFAULT 0 NOT NULL,
  count_resolved_filed_since_pandemic   integer DEFAULT 0 NOT NULL,
  count_overdue_filed_since_pandemic    integer DEFAULT 0 NOT NULL,
  count_overdue                         integer DEFAULT 0 NOT NULL,
  count_overdue_a                       integer DEFAULT 0 NOT NULL,
  count_overdue_b                       integer DEFAULT 0 NOT NULL,
  count_overdue_c                       integer DEFAULT 0 NOT NULL,
  mean_days_overdue                     numeric(10) DEFAULT 0 NOT NULL,
  max_overdue                           integer DEFAULT 0 NOT NULL,
  overdue_mean_days_since_inspection    numeric(10) DEFAULT 0 NOT NULL,
  pre_pandemic_resolved_count           integer DEFAULT 0 NOT NULL,
  pre_pandemic_mean_resolution_days     numeric(10) DEFAULT 0 NOT NULL,
  updated_at                            timestamp default current_timestamp
);

CREATE INDEX IF NOT EXISTS buildings_boroid_idx ON buildings (boroid);
CREATE INDEX IF NOT EXISTS buildings_nta_idx ON buildings (nta);
CREATE INDEX IF NOT EXISTS buildings_count_filed_since_pandemic_idx ON buildings (count_filed_since_pandemic);
CREATE INDEX IF NOT EXISTS buildings_count_overdue_idx ON buildings (count_overdue);
CREATE INDEX IF NOT EXISTS buildings_mean_days_overdue_idx ON buildings (mean_days_overdue);
CREATE INDEX IF NOT EXISTS buildings_max_overdue_idx ON buildings (max_overdue);
CREATE INDEX IF NOT EXISTS buildings_pre_pandemic_mean_resolution_days_idx ON buildings (pre_pandemic_mean_resolution_days);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_building_updated_at
BEFORE UPDATE ON buildings
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_violation_updated_at
BEFORE UPDATE ON housing_violations
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
