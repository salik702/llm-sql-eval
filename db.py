from pathlib import Path
import sqlite3


def build_database() -> None:
    project_dir = Path(__file__).resolve().parent

    sql_file = project_dir / "university_eval.sql"
    database_file = project_dir / "university_eval.db"

    if not sql_file.exists():
        raise FileNotFoundError(
            f"SQL file not found: {sql_file}"
        )

    sql_script = sql_file.read_text(encoding="utf-8")

    # Delete the old database so it is rebuilt from scratch.
    if database_file.exists():
        database_file.unlink()

    connection = sqlite3.connect(database_file)

    try:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.executescript(sql_script)
        connection.commit()

    except Exception:
        connection.rollback()

        # Remove partially created database.
        connection.close()

        if database_file.exists():
            database_file.unlink()

        raise

    finally:
        if connection:
            connection.close()

    print("Database created successfully!")
    print(f"SQL file: {sql_file}")
    print(f"Database file: {database_file}")


if __name__ == "__main__":
    build_database()