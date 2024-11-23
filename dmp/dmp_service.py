import sys
import json
import typing
import logging
import requests
import psycopg2

from kafka import KafkaConsumer


logging.basicConfig(level=logging.INFO, stream=sys.stdout)
logger = logging.getLogger('dmp_service')

TOPICS = [
    'connect_configs',
    'connect_offsets',
    'connect_statuses',
    '_schemas',
    '__debezium-heartbeat.pg-dev',
    '__debezium-heartbeat.postgres',
]


def fetch_cluster_id() -> str:
    response = requests.get('http://rest-proxy:8082/v3/clusters').json()
    return response['data'][0]['cluster_id']


def fetch_topics(cluster_id: str) -> list[str]:
    meta_url = f'http://rest-proxy:8082/v3/clusters/{cluster_id}/topics'
    response = requests.get(meta_url).json()
    return [topic['topic_name'] for topic in response['data'] if topic['topic_name'] not in TOPICS]


def connect():
    return psycopg2.connect(
        dbname="postgres",
        user="postgres",
        password="postgres",
        host="postgres_dwh",
        port="5432"
    )


def create_consumer() -> KafkaConsumer:
    return KafkaConsumer(
        bootstrap_servers='broker:29092',
        value_deserializer=lambda v: json.loads(v.decode("utf-8")),
        auto_offset_reset="earliest",
        group_id='backend'
    )


def handle_event(table_name: str, data: dict):
    # переписать вставку для каждой таблицы из нашей базы
    ####
    if table_name != 'categories':
        return

    dwh_conn = connect()
    cursor = dwh_conn.cursor()

    query_hub = f"INSERT INTO " \
                f"dwh_detailed.hub_categories (hub_category_id, load_ts, record_source) " \
                f"VALUES ({data['category_id']}, NOW(), 'source_system')" \
                f"ON CONFLICT DO NOTHING"
    query_sat = f"INSERT INTO " \
                f"dwh_detailed.sat_categories (sat_category_id, category_name, load_ts, record_source)" \
                f"VALUES ({data['category_id']}, '{data['category_name']}', NOW(), 'source_system')"

    cursor.execute(query_hub)
    cursor.execute(query_sat)
    ####

    dwh_conn.commit()
    dwh_conn.close()


def process_events(consumer: KafkaConsumer):
    try:
        for message in consumer:
            value = message.value
            print(value)
            value = value['payload']
            handle_event(table_name=value['source']['table'], data=value['after'])
    except Exception as e:
            print("Closing consumer, error\n")
            consumer.close()
            raise e
    finally:
        print("Consumer finish, finally\n")
        consumer.close()


def main():
    logger.info('start dmp service')
    cluster_id = fetch_cluster_id()
    logger.info('successfully fetched cluster_id: %s', cluster_id)
    topics = fetch_topics(cluster_id)
    logger.info('successfully fetched topics: %s', topics)

    print(topics)

    consumer = create_consumer()
    consumer.subscribe(topics)
    process_events(consumer)


if __name__ == '__main__':
    main()
