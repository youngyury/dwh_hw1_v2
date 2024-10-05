import csv
from random import randint
from datetime import datetime, timedelta
import json


def create_csv_file_with_data(path, headers, rows):
    with open(path, mode="w", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        writer.writerows(rows)


def random_datetime(start, end):
    return start + timedelta(seconds=randint(0, int((end - start).total_seconds())))


def generate_bookings_data():
    return [
        [
            "A00001",
            random_datetime(datetime(2024, 1, 1), datetime(2024, 12, 31)),
            round(randint(100, 1000) + randint(0, 99) / 100, 2)
        ],
        [
            "A00002",
            random_datetime(datetime(2024, 1, 1), datetime(2024, 12, 31)),
            round(randint(100, 1000) + randint(0, 99) / 100, 2)
        ]
    ]


def generate_tickets_data():
    return [
        ["TCKT001", "A00001", "P001", "John Doe", json.dumps({"phone": "123456789", "email": "john@example.com"})],
        ["TCKT002", "A00002", "P002", "Jane Smith", json.dumps({"phone": "987654321", "email": "jane@example.com"})],
    ]


def generate_ticket_flights_data():
    return [
        ["TCKT001", 101, "Economy", round(randint(100, 500) + randint(0, 99) / 100, 2)],
        ["TCKT002", 102, "Business", round(randint(100, 500) + randint(0, 99) / 100, 2)],
    ]


def generate_boarding_passes_data():
    return [
        ["TCKT001", 101, 1, "12A"],
        ["TCKT002", 102, 2, "15C"],
    ]


def generate_flights_data():
    return [
        [101, "FL123", random_datetime(datetime(2024, 1, 1), datetime(2024, 12, 31)), random_datetime(datetime(2024, 1, 1), datetime(2024, 12, 31)), "JFK", "LAX", "Scheduled", "A32", None, None],
        [102, "FL124", random_datetime(datetime(2024, 1, 1), datetime(2024, 12, 31)), random_datetime(datetime(2024, 1, 1), datetime(2024, 12, 31)), "LAX", "JFK", "Scheduled", "B73", None, None],
    ]


def generate_airports_data():
    return [
        ["JFK", "John F. Kennedy International Airport", "New York", -73.7781, 40.6413, "America/New_York"],
        ["LAX", "Los Angeles International Airport", "Los Angeles", -118.4079971, 33.94250107, "America/Los_Angeles"],
    ]


def generate_aircrafts_data():
    return [
        ["A32", json.dumps({"manufacturer": "Airbus", "type": "A32"}), 6000],
        ["B73", json.dumps({"manufacturer": "Boeing", "type": "737"}), 5600],
    ]


def generate_seats_data():
    return [
        ["A32", "12A", "Economy"],
        ["B73", "15C", "Business"],
    ]


csv_config = {
    "flights": {
        "path": "data_example/flights.csv",
        "headers": [
            "flight_id",
            "flight_no",
            "scheduled_departure",
            "scheduled_arrival",
            "departure_airport",
            "arrival_airport",
            "status",
            "aircraft_code",
            "actual_departure",
            "actual_arrival"
        ],
        "rows": generate_flights_data()
    },
    "ticket_flights": {
        "path": "data_example/ticket_flights.csv",
        "headers": ["ticket_no", "flight_id", "fare_conditions", "amount"],
        "rows": generate_ticket_flights_data()
    },
    "boarding_passes": {
        "path": "data_example/boarding_passes.csv",
        "headers": ["ticket_no", "flight_id", "boarding_no", "seat_no"],
        "rows": generate_boarding_passes_data()
    },
    "tickets": {
        "path": "data_example/tickets.csv",
        "headers": ["ticket_no", "book_ref", "passenger_id", "passenger_name", "contact_data"],
        "rows": generate_tickets_data()
    },
    "bookings": {
        "path": "data_example/bookings.csv",
        "headers": ["book_ref", "book_date", "total_amount"],
        "rows": generate_bookings_data()
    },
    "airports": {
        "path": "data_example/airports.csv",
        "headers": ["airport_code", "airport_name", "city", "coordinates_lon", "coordinates_lat", "timezone"],
        "rows": generate_airports_data()
    },
    "aircrafts": {
        "path": "data_example/aircrafts.csv",
        "headers": ["aircraft_code", "model", "range"],
        "rows": generate_aircrafts_data()
    },
    "seats": {
        "path": "data_example/seats.csv",
        "headers": ["aircraft_code", "seat_no", "fare_conditions"],
        "rows": generate_seats_data()
    },
}

for config in csv_config.values():
    create_csv_file_with_data(**config)
