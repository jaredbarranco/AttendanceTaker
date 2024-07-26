package db

import (
	"database/sql"
	_ "github.com/lib/pq"
	"os"
)

func PgConnect(
	host string,
	username string,
	dbname string,
	passEnvVar string,
) (*sql.DB, error) {
	connStr := "postgresql://" + username + ":" + os.Getenv(passEnvVar) + "@" + host + "/" + dbname
	print(connStr)
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, err
	}
	if err = db.Ping(); err != nil {
		return nil, err
	}

	return db, nil
}

func PgClose(db *sql.DB) error {
	err := db.Close()
	return err
}
