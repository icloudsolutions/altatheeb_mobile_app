"""Background worker: RQ queue processor (FCM sends, reconciliation pulls)."""

import logging

from redis import Redis
from rq import Queue, Worker

from ..core.settings import get_settings

logging.basicConfig(level=logging.INFO)


def main() -> None:
    settings = get_settings()
    conn = Redis.from_url(settings.redis_url)
    queues = [Queue("default", connection=conn), Queue("fcm", connection=conn)]
    worker = Worker(queues, connection=conn)
    worker.work(with_scheduler=True)


if __name__ == "__main__":
    main()
