from sqlalchemy import inspect, text
from database.connection import engine


def migrate():
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    if "tasks" not in tables:
        print("TASK TABLE DOES NOT EXIST.")
        return

    existing_columns = {
        column["name"]
        for column in inspector.get_columns("tasks")
    }

    migrations = [
        ("mission_id", "ALTER TABLE tasks ADD COLUMN mission_id VARCHAR"),
        ("depends_on", "ALTER TABLE tasks ADD COLUMN depends_on TEXT"),
        ("verification_status", "ALTER TABLE tasks ADD COLUMN verification_status VARCHAR DEFAULT 'pending'"),
        ("worker_id", "ALTER TABLE tasks ADD COLUMN worker_id VARCHAR"),
        ("lease_expires_at", "ALTER TABLE tasks ADD COLUMN lease_expires_at DATETIME"),
        ("heartbeat_at", "ALTER TABLE tasks ADD COLUMN heartbeat_at DATETIME"),
        ("next_retry_at", "ALTER TABLE tasks ADD COLUMN next_retry_at DATETIME"),
    ]

    applied = 0

    with engine.begin() as connection:
        for column_name, sql in migrations:
            if column_name in existing_columns:
                print(f"SKIP: {column_name}")
                continue

            connection.execute(text(sql))
            print(f"ADDED: {column_name}")
            applied += 1

    print(f"SAGE DATABASE MIGRATION COMPLETE. {applied} change(s) applied.")


if __name__ == "__main__":
    migrate()
