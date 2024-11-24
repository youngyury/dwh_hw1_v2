DROP SCHEMA IF EXISTS company_dwh CASCADE;
CREATE SCHEMA company_dwh;

-- hubs
CREATE TABLE company_dwh.bookings_hub (
    hub_booking_id SERIAL PRIMARY KEY,
    book_ref CHAR(6) NOT NULL,
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.airports_hub (
    hub_airport_id SERIAL PRIMARY KEY,
    airport_code CHAR(3) NOT NULL,
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.aircrafts_hub (
    hub_aircraft_id SERIAL PRIMARY KEY,
    aircraft_code CHAR(3) NOT NULL,
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.flights_hub (
    hub_flight_id SERIAL PRIMARY KEY,
    flight_id SERIAL NOT NULL,
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.tickets_hub (
    hub_ticket_id SERIAL PRIMARY KEY,
    ticket_no CHAR(13) NOT NULL,
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

-- sats
CREATE TABLE company_dwh.bookings_sat (
    sat_booking_id SERIAL PRIMARY KEY,
    hub_booking_id INTEGER NOT NULL REFERENCES company_dwh.bookings_hub(hub_booking_id),
    book_date TIMESTAMPTZ NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL,
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.airports_sat (
    sat_airport_id SERIAL PRIMARY KEY,
    hub_airport_id INTEGER NOT NULL REFERENCES company_dwh.airports_hub(hub_airport_id),
    airport_name TEXT NOT NULL,
    city TEXT NOT NULL,
    coordinates_lon DOUBLE PRECISION NOT NULL,
    coordinates_lat DOUBLE PRECISION NOT NULL,
    timezone TEXT NOT NULL,
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.aircrafts_sat (
    sat_aircraft_id SERIAL PRIMARY KEY,
    hub_aircraft_id INTEGER NOT NULL REFERENCES company_dwh.aircrafts_hub(hub_aircraft_id),
    model JSONB NOT NULL,
    range INTEGER NOT NULL,
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

-- links
CREATE TABLE company_dwh.flights_link (
    link_flight_airport_id SERIAL PRIMARY KEY,
    hub_flight_id INTEGER NOT NULL REFERENCES company_dwh.flights_hub(hub_flight_id),
    hub_departure_airport_id INTEGER NOT NULL REFERENCES company_dwh.airports_hub(hub_airport_id),
    hub_arrival_airport_id INTEGER NOT NULL REFERENCES company_dwh.airports_hub(hub_airport_id),
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.aircraft_flights_link (
    link_aircraft_flight_id SERIAL PRIMARY KEY,
    hub_flight_id INTEGER NOT NULL REFERENCES company_dwh.flights_hub(hub_flight_id),
    hub_aircraft_id INTEGER NOT NULL REFERENCES company_dwh.aircrafts_hub(hub_aircraft_id),
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.ticket_bookings_link (
    link_ticket_booking_id SERIAL PRIMARY KEY,
    hub_ticket_id INTEGER NOT NULL REFERENCES company_dwh.tickets_hub(hub_ticket_id),
    hub_booking_id INTEGER NOT NULL REFERENCES company_dwh.bookings_hub(hub_booking_id),
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.ticket_flights_link (
    link_ticket_flight_id SERIAL PRIMARY KEY,
    hub_ticket_id INTEGER NOT NULL REFERENCES company_dwh.tickets_hub(hub_ticket_id),
    hub_flight_id INTEGER NOT NULL REFERENCES company_dwh.flights_hub(hub_flight_id),
    fare_conditions VARCHAR(10) NOT NULL,
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);

CREATE TABLE company_dwh.boarding_passes_link (
    link_boarding_pass_id SERIAL PRIMARY KEY,
    hub_ticket_id INTEGER NOT NULL REFERENCES company_dwh.tickets_hub(hub_ticket_id),
    hub_flight_id INTEGER NOT NULL REFERENCES company_dwh.flights_hub(hub_flight_id),
    load_ts TIMESTAMPTZ NOT NULL,
    record_source VARCHAR(255) NOT NULL
);
