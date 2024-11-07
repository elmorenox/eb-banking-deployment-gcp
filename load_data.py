import sys
import csv
import os
from database import Base, Accounts, Customers, Users, CustomerLog, Transactions
from sqlalchemy import create_engine, text
from sqlalchemy.orm import scoped_session, sessionmaker
from flask_bcrypt import Bcrypt 
from flask import Flask

application = Flask(__name__)
engine = create_engine('sqlite:///database.db', connect_args={'check_same_thread': False}, echo=True)
Base.metadata.bind = engine
db = scoped_session(sessionmaker(bind=engine))
bcrypt = Bcrypt(application)

def accounts():
    users = [
        ('C00000001', 'ramesh', 'executive', 'Ramesh@001'),
        ('C00000002', 'suresh', 'cashier', 'Suresh@002'),
        ('C00000003', 'mahesh', 'teller', 'Mahesh@003')
    ]

    for usern, name, usert, passw in users:
        passw_hash = bcrypt.generate_password_hash(passw).decode('utf-8')
        db.execute(
            text("INSERT INTO users (id, name, user_type, password) VALUES (:u, :n, :t, :p)"),
            {"u": usern, "n": name, "t": usert, "p": passw_hash}
        )
        db.commit()
        print(f"Account for {name} ({usert}) completed.")

if __name__ == "__main__":
    accounts()
