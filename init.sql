CREATE TABLE public.bookings (
    book_ref CHAR(6) PRIMARY KEY,
    book_date timestamptz NOT NULL,
    total_amount numeric(10,2) NOT NULL
);

CREATE TABLE public.airports (
    airport_code CHAR(3) PRIMARY KEY,
    airport_name TEXT NOT NULL,
    city TEXT NOT NULL,
    coordinates_lon DOUBLE PRECISION NOT NULL,
    coordinates_lat DOUBLE PRECISION NOT NULL,
    timezone TEXT NOT NULL
);

CREATE TABLE public.flights (
    flight_id SERIAL PRIMARY KEY,
    flight_no CHAR(6) NOT NULL,
    scheduled_departure timestamptz NOT NULL,
    scheduled_arrival timestamptz NOT NULL,
    departure_airport CHAR(3) REFERENCES public.airports(airport_code),
    arrival_airport CHAR(3) REFERENCES public.airports(airport_code),
    status VARCHAR(20) NOT NULL,
    aircraft_code CHAR(3) REFERENCES public.aircrafts(aircraft_code),
    actual_departure timestamptz,
    actual_arrival timestamptz
);

CREATE TABLE public.aircrafts (
    aircraft_code CHAR(3) PRIMARY KEY,
    model JSONB NOT NULL,
    range INTEGER NOT NULL
);

CREATE TABLE public.seats (
    aircraft_code CHAR(3) REFERENCES public.aircrafts(aircraft_code),
    seat_no VARCHAR(4),
    fare_conditions VARCHAR(10),
    PRIMARY KEY (aircraft_code, seat_no)
);

CREATE TABLE public.tickets (
    ticket_no CHAR(13) PRIMARY KEY,
    book_ref CHAR(6) REFERENCES public.bookings(book_ref),
    passenger_id VARCHAR(20) NOT NULL,
    passenger_name TEXT NOT NULL,
    contact_data JSONB
);

CREATE TABLE public.ticket_flights (
    ticket_no CHAR(13) REFERENCES public.tickets(ticket_no),
    flight_id INTEGER REFERENCES public.flights(flight_id),
    fare_conditions VARCHAR(10) NOT NULL,
    amount numeric(10,2) NOT NULL,
    PRIMARY KEY (ticket_no, flight_id)
);

CREATE TABLE public.boarding_passes (
    ticket_no CHAR(13) REFERENCES public.tickets(ticket_no),
    flight_id INTEGER REFERENCES public.flights(flight_id),
    boarding_no INTEGER NOT NULL,
    seat_no VARCHAR(4),
    PRIMARY KEY (ticket_no, flight_id)
);
