# create_db.py
import sqlite3

def create_user_table():
    conn = sqlite3.connect('userData.db')
    cur = conn.cursor()
    cur.execute('''
    CREATE TABLE IF NOT EXISTS user_profile (
        id TEXT PRIMARY KEY,
        brand_name TEXT NOT NULL,
        user_weight REAL NOT NULL,
        battery_soc REAL NOT NULL
    )
    ''')
    conn.commit()
    conn.close()

if __name__ == "__main__":
    create_user_table()
    print("user_profile 테이블 생성 완료")