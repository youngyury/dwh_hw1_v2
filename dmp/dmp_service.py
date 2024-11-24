import logging
import json
import requests
import sys
import typing

from kafka import KafkaConsumer
import psycopg2

logging.basicConfig(level=logging.INFO, stream=sys.stdout)
logger = logging.getLogger('dmp_service')

DEF_TOPICS = ['connect_configs', 'connect_offsets', 'connect_statuses', '_schemas', '__debezium-heartbeat.pg-dev']

# PostgreSQL connection settings
DWH_SETTINGS = {
    "dbname": "postgres",
    "user": "postgres",
    "password": "postgres",
    "host": "postgres_dwh",
    "port": "5432",
}


def fetch_cluster_id() -> str:
    response = requests.get('http://rest-proxy:8082/v3/clusters').json()
    return response['data'][0]['cluster_id']


def fetch_topics(cluster_id: str) -> typing.List[str]:
    meta_url = f'http://rest-proxy:8082/v3/clusters/{cluster_id}/topics'
    response = requests.get(meta_url).json()
    topics = [
        topic['topic_name']
        for topic in response['data']
        if topic['topic_name'] not in DEF_TOPICS
    ]
    return topics


def connect():
    """Establish a connection to the DWH."""
    return psycopg2.connect(**DWH_SETTINGS)


def create_consumer() -> KafkaConsumer:
    consumer = KafkaConsumer(
        bootstrap_servers='broker:29092',
        value_deserializer=lambda v: json.loads(v.decode("utf-8")),
        auto_offset_reset="earliest",
        group_id='backend',
    )
    return consumer


def handle_hub_event(table_name: str, data: dict, cursor):
    """Insert data into a hub table."""
    hub_table = f"dwh_detailed.{table_name}_hub"
    record_source = "source_system"

    query = f"""
    INSERT INTO {hub_table} (hub_{table_name}_id, load_ts, record_source)
    VALUES (%s, NOW(), %s)
    ON CONFLICT DO NOTHING
    """
    cursor.execute(query, (data[f"{table_name}_id"], record_source))


def handle_sat_event(table_name: str, data: dict, cursor):
    """Insert data into a satellite table."""
    sat_table = f"dwh_detailed.{table_name}_sat"
    record_source = "source_system"
    columns = ", ".join(data.keys())
    values = ", ".join(["%s"] * len(data))
    query = f"""
    INSERT INTO {sat_table} ({columns}, load_ts, record_source)
    VALUES ({values}, NOW(), %s)
    """
    cursor.execute(query, (*data.values(), record_source))


def handle_link_event(table_name: str, data: dict, cursor):
    """Insert data into a link table."""
    link_table = f"dwh_detailed.{table_name}_link"
    record_source = "source_system"
    columns = ", ".join(data.keys())
    values = ", ".join(["%s"] * len(data))
    query = f"""
    INSERT INTO {link_table} ({columns}, load_ts, record_source)
    VALUES ({values}, NOW(), %s)
    """
    cursor.execute(query, (*data.values(), record_source))


def handle_event(table_name: str, data: dict):
    """Process events for a specific table."""
    dwh_conn = connect()
    cursor = dwh_conn.cursor()

    try:
        if table_name.endswith("_hub"):
            handle_hub_event(table_name.replace("_hub", ""), data, cursor)
        elif table_name.endswith("_sat"):
            handle_sat_event(table_name.replace("_sat", ""), data, cursor)
        elif table_name.endswith("_link"):
            handle_link_event(table_name.replace("_link", ""), data, cursor)
        else:
            logger.warning("Unrecognized table type: %s", table_name)

        dwh_conn.commit()
    except Exception as e:
        logger.error("Error processing event for table %s: %s", table_name, str(e))
        dwh_conn.rollback()
    finally:
        dwh_conn.close()


def process_events(consumer: KafkaConsumer):
    """Process incoming Kafka events."""
    try:
        for message in consumer:
            value = message.value
            payload = value['payload']
            table_name = payload['source']['table']
            data = payload['after']
            logger.info("Processing table: %s, data: %s", table_name, data)
            handle_event(table_name, data)
    except Exception as e:
        logger.error("Error processing events: %s", str(e))
        consumer.close()
        raise
    finally:
        consumer.close()


def main():
    logger.info('Start DMP Service')
    cluster_id = fetch_cluster_id()
    logger.info('Successfully fetched cluster_id: %s', cluster_id)
    topics = fetch_topics(cluster_id)
    logger.info('Successfully fetched topics: %s', topics)

    consumer = create_consumer()
    consumer.subscribe(topics)
    process_events(consumer)


if __name__ == '__main__':
    main()
