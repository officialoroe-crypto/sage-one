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
        (
            "mission_id",
            """
            ALTER TABLE tasks
            ADD COLUMN mission_id VARCHAR
            """
        ),
        (
            "depends_on",
            """
            ALTER TABLE tasks
            ADD COLUMN depends_on TEXT
            """
        ),
        (
            "verification_status",
            """
            ALTER TABLE tasks
            ADD COLUMN verification_status VARCHAR
            DEFAULT 'pending'
            """
        ),
    ]

    applied = 0

    with engine.begin() as connection:

        for column_name, sql in migrations:

            if column_name in existing_columns:

                print(
                    f"SKIP: {column_name} already exists."
                )

                continue

            connection.execute(
                text(sql)
            )

            print(
                f"ADDED: {column_name}"
            )

            applied += 1

    print()
    print(
        f"SAGE DATABASE MIGRATION COMPLETE. "
        f"{applied} column(s) added."
    )


if __name__ == "__main__":
    migrate()