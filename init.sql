DROP SCHEMA IF EXISTS company CASCADE;
CREATE SCHEMA company;

CREATE TABLE company.bookings (
    book_ref CHAR(6) PRIMARY KEY,
    book_date timestamptz NOT NULL,
    total_amount numeric(10,2) NOT NULL
);
COPY company.bookings
    FROM '/var/lib/postgresql/example_data/bookings.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE company.airports (
    airport_code CHAR(3) PRIMARY KEY,
    airport_name TEXT NOT NULL,
    city TEXT NOT NULL,
    coordinates_lon DOUBLE PRECISION NOT NULL,
    coordinates_lat DOUBLE PRECISION NOT NULL,
    timezone TEXT NOT NULL
);
COPY company.airports
    FROM '/var/lib/postgresql/example_data/airports.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE company.aircrafts (
    aircraft_code CHAR(3) PRIMARY KEY,
    model JSONB NOT NULL,
    range INTEGER NOT NULL
);
COPY company.aircrafts
    FROM '/var/lib/postgresql/example_data/aircrafts.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE company.flights (
    flight_id SERIAL PRIMARY KEY,
    flight_no CHAR(6) NOT NULL,
    scheduled_departure timestamptz NOT NULL,
    scheduled_arrival timestamptz NOT NULL,
    departure_airport CHAR(3) REFERENCES company.airports(airport_code),
    arrival_airport CHAR(3) REFERENCES company.airports(airport_code),
    status VARCHAR(20) NOT NULL,
    aircraft_code CHAR(3) REFERENCES company.aircrafts(aircraft_code),
    actual_departure timestamptz,
    actual_arrival timestamptz
);
COPY company.flights
    FROM '/var/lib/postgresql/example_data/flights.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE company.seats (
    aircraft_code CHAR(3) REFERENCES company.aircrafts(aircraft_code),
    seat_no VARCHAR(4),
    fare_conditions VARCHAR(10),
    PRIMARY KEY (aircraft_code, seat_no)
);
COPY company.seats
    FROM '/var/lib/postgresql/example_data/seats.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE company.tickets (
    ticket_no CHAR(13) PRIMARY KEY,
    book_ref CHAR(6) REFERENCES company.bookings(book_ref),
    passenger_id VARCHAR(20) NOT NULL,
    passenger_name TEXT NOT NULL,
    contact_data JSONB
);
COPY company.tickets
    FROM '/var/lib/postgresql/example_data/tickets.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE company.ticket_flights (
    ticket_no CHAR(13) REFERENCES company.tickets(ticket_no),
    flight_id INTEGER REFERENCES company.flights(flight_id),
    fare_conditions VARCHAR(10) NOT NULL,
    amount numeric(10,2) NOT NULL,
    PRIMARY KEY (ticket_no, flight_id)
);
COPY company.ticket_flights
    FROM '/var/lib/postgresql/example_data/ticket_flights.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE company.boarding_passes (
    ticket_no CHAR(13) REFERENCES company.tickets(ticket_no),
    flight_id INTEGER REFERENCES company.flights(flight_id),
    boarding_no INTEGER NOT NULL,
    seat_no VARCHAR(4),
    PRIMARY KEY (ticket_no, flight_id)
);
COPY company.boarding_passes
    FROM '/var/lib/postgresql/example_data/boarding_passes.csv' DELIMITER ',' CSV HEADER;


CREATE VIEW company.airport_passenger_flow AS
SELECT
    airport_code,
    COUNT(DISTINCT CASE WHEN f.departure_airport = a.airport_code THEN f.flight_id END) AS departure_flights_num,
    COUNT(DISTINCT CASE WHEN f.departure_airport = a.airport_code THEN t.ticket_no END) AS departure_psngr_num,
    COUNT(DISTINCT CASE WHEN f.arrival_airport = a.airport_code THEN f.flight_id END) AS arrival_flights_num,
    COUNT(DISTINCT CASE WHEN f.arrival_airport = a.airport_code THEN t.ticket_no END) AS arrival_psngr_num
FROM company.airports a
LEFT JOIN company.flights f
    ON a.airport_code = f.departure_airport OR a.airport_code = f.arrival_airport
LEFT JOIN company.ticket_flights tf
    ON f.flight_id = tf.flight_id
LEFT JOIN company.tickets t
    ON tf.ticket_no = t.ticket_no
GROUP BY a.airport_code;