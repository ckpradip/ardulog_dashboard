-- flight_analytics.aircraft definition
CREATE TABLE IF NOT EXISTS aircraft (
  id SERIAL PRIMARY KEY,
  platform VARCHAR(64) NOT NULL,
  designation VARCHAR(64) NOT NULL,
  registration VARCHAR(64) DEFAULT NULL,
  UNIQUE (platform, designation),
  UNIQUE (registration)
);

-- flight_analytics.autopilot definition
CREATE TABLE IF NOT EXISTS autopilot (
  id SERIAL PRIMARY KEY,
  hardware VARCHAR(50) NOT NULL
);

-- flight_analytics.pilot definition
CREATE TABLE IF NOT EXISTS pilot (
  id SERIAL PRIMARY KEY,
  name VARCHAR(40) NOT NULL,
  surname VARCHAR(40) NOT NULL
);

-- flight_analytics.prevhashes definition
CREATE TABLE IF NOT EXISTS prevhashes (
  processed VARCHAR(256) NOT NULL
);

-- flight_analytics.aircraft_autopilot definition
CREATE TABLE IF NOT EXISTS aircraft_autopilot (
  aircraft INT NOT NULL,
  autopilot INT NOT NULL,
  tune_hash BYTEA NOT NULL,
  last_seen TIMESTAMP NOT NULL,
  PRIMARY KEY (autopilot, tune_hash),
  UNIQUE (autopilot, tune_hash),
  FOREIGN KEY (aircraft) REFERENCES aircraft (id) ON UPDATE CASCADE,
  FOREIGN KEY (autopilot) REFERENCES autopilot (id) ON UPDATE CASCADE
);

-- flight_analytics.aircraft_autopilot_override definition
CREATE TABLE IF NOT EXISTS aircraft_autopilot_override (
  autopilot INT NOT NULL,
  aircraft INT NOT NULL,
  start_date DATE DEFAULT NULL,
  end_date DATE DEFAULT NULL,
  FOREIGN KEY (autopilot) REFERENCES autopilot (id) ON UPDATE CASCADE,
  FOREIGN KEY (aircraft) REFERENCES aircraft (id) ON UPDATE CASCADE,
  CONSTRAINT aircraft_manual_override_FK FOREIGN KEY (autopilot) REFERENCES autopilot (id) ON UPDATE CASCADE,
  CONSTRAINT aircraft_manual_override_FK_1 FOREIGN KEY (aircraft) REFERENCES aircraft (id) ON UPDATE CASCADE
);
COMMENT ON TABLE aircraft_autopilot_override IS 'This table is needed for cases where an autopilot shows up in multiple different airframes of a single platform. It provides a way to force a particular autopilot to register as a specific aircraft within a date range.';

-- flight_analytics.file definition
CREATE TABLE IF NOT EXISTS file (
  id SERIAL PRIMARY KEY,
  filename VARCHAR(255) NOT NULL,
  folder VARCHAR(255) NOT NULL,
  start_time TIMESTAMP NOT NULL,
  start_time_boot INT NOT NULL,
  duration INT NOT NULL,
  starts_armed BOOLEAN NOT NULL,
  ends_armed BOOLEAN NOT NULL,
  firmware_info VARCHAR(50) DEFAULT NULL,
  git_hash VARCHAR(16) DEFAULT NULL,
  autopilot INT NOT NULL,
  aircraft INT NOT NULL,
  md5hash BYTEA NOT NULL,
  UNIQUE (md5hash),
  UNIQUE (filename, folder),
  FOREIGN KEY (aircraft) REFERENCES aircraft (id) ON UPDATE CASCADE,
  FOREIGN KEY (autopilot) REFERENCES autopilot (id) ON UPDATE CASCADE
);

-- flight_analytics.flight definition
CREATE TABLE IF NOT EXISTS flight (
  id SERIAL PRIMARY KEY,
  takeoff_time TIMESTAMP DEFAULT NULL,
  takeoff_time_boot INT NOT NULL,
  takeoff_location_x NUMERIC NOT NULL,
  takeoff_location_y NUMERIC NOT NULL,
  duration INT DEFAULT NULL,
  utc_offset SMALLINT DEFAULT NULL,
  autopilot INT NOT NULL,
  aircraft INT NOT NULL,
  pilot_id INT DEFAULT NULL,
  gso_id INT DEFAULT NULL,
  FOREIGN KEY (pilot_id) REFERENCES pilot (id) ON UPDATE CASCADE,
  FOREIGN KEY (gso_id) REFERENCES pilot (id) ON UPDATE CASCADE,
  FOREIGN KEY (aircraft) REFERENCES aircraft (id) ON UPDATE CASCADE,
  FOREIGN KEY (autopilot) REFERENCES autopilot (id) ON UPDATE CASCADE
);

-- flight_analytics.flight_file definition
CREATE TABLE IF NOT EXISTS flight_file (
  file_id INT NOT NULL,
  flight_id INT NOT NULL,
  PRIMARY KEY (flight_id, file_id),
  FOREIGN KEY (file_id) REFERENCES file (id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (flight_id) REFERENCES flight (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- flight_analytics."Aircraft Info" source
CREATE OR REPLACE VIEW "Aircraft Info" AS
SELECT
    aircraft.id AS aircraft_id,
    aircraft.platform AS platform,
    aircraft.designation AS designation,
    aircraft.registration AS registration,
    autopilot.id AS autopilot_id,
    autopilot.hardware AS hardware,
    encode(aircraft_autopilot.tune_hash, 'hex') AS tune_hash,
    aircraft_autopilot.last_seen AS last_seen
FROM
    aircraft
JOIN aircraft_autopilot ON aircraft.id = aircraft_autopilot.aircraft
JOIN autopilot ON aircraft_autopilot.autopilot = autopilot.id;

-- flight_analytics."Flight Details" source
CREATE OR REPLACE VIEW "Flight Details" AS
SELECT
    flight.id AS ID,
    flight.takeoff_time AS Time,
    flight.duration AS Duration,
    --flight.takeoff_location AS Location,
    POINT(flight.takeoff_location_x, flight.takeoff_location_y) AS Location,
    aircraft.platform AS Platform,
    aircraft.platform || ' ' || aircraft.designation AS Designation,
    autopilot.hardware AS "Hardware ID",
    string_agg(file.filename, '\n') AS Files
FROM
    flight
JOIN aircraft ON flight.aircraft = aircraft.id
JOIN autopilot ON flight.autopilot = autopilot.id
JOIN flight_file ON flight_file.flight_id = flight.id
JOIN file ON flight_file.file_id = file.id
GROUP BY
    flight.id, flight.takeoff_time, flight.duration, flight.takeoff_location_x, flight.takeoff_location_y, aircraft.platform, aircraft.designation, autopilot.hardware;


