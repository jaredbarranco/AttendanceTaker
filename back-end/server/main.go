package main

import (
	"attendance-taker/db"
	"encoding/json"
	_ "github.com/lib/pq"
	"log"
	"net/http"
	"strconv"
)

type Event struct {
	ID            int    `json:"id"`
	Name          string `json:"name"`
	StartDateTime string `json:"startDateTime"`
	EndDateTime   string `json:"endDateTime"`
	Location      string `json:"location"`
	EventType     int32  `json:eventType`
}

var items = []Event{
	{ID: 1, Name: "Event One", StartDateTime: "2024-07-12 12:01:05.098765", EndDateTime: "2024-07-12 12:01:05.098765", Location: "Chapter House", EventType: 1},
	{ID: 2, Name: "Event Two", StartDateTime: "2024-07-13 12:01:05.098765", EndDateTime: "2024-07-13 12:01:05.098765", Location: "Chapter House", EventType: 1},
}

func main() {
	http.HandleFunc("/event", eventHandler)
	http.HandleFunc("/events", eventsHandler)
	log.Println("Starting server on :8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func eventsHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		getEvents(w, r)
	case "POST":
		createEvent(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func eventHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		getEvent(w, r)
	case "PATCH":
		updateEvent(w, r)
	case "DELETE":
		deleteEvent(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func getEvents(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	dbconn, error := db.PgConnect("localhost", "jbarranco", "dbname", "POSTGRES_PASSWORD")
	if error != nil {
		http.Error(w, error.Error(), http.StatusInternalServerError)
	}
	defer db.PgClose(dbconn)
	rows, error := dbconn.Query("SELECT * FROM events;")
	if error != nil {
		http.Error(w, error.Error(), http.StatusInternalServerError)
	}
	// handle rows here - slice, iterate, format
	defer rows.Close()

	json.NewEncoder(w).Encode(items)
}

func createEvent(w http.ResponseWriter, r *http.Request) {
	var newEvent Event
	err := json.NewDecoder(r.Body).Decode(&newEvent)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	newEvent.ID = len(items) + 1
	items = append(items, newEvent)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(newEvent)
}

func getEvent(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.URL.Path[len("/items/"):])
	if err != nil {
		http.Error(w, "Invalid item ID", http.StatusBadRequest)
		return
	}
	for _, item := range items {
		if item.ID == id {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(item)
			return
		}
	}
	http.Error(w, "Event not found", http.StatusNotFound)
}

func updateEvent(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.URL.Path[len("/items/"):])
	if err != nil {
		http.Error(w, "Invalid item ID", http.StatusBadRequest)
		return
	}
	var updatedEvent Event
	err = json.NewDecoder(r.Body).Decode(&updatedEvent)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	for i, item := range items {
		if item.ID == id {
			items[i].Name = updatedEvent.Name
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(items[i])
			return
		}
	}
	http.Error(w, "Event not found", http.StatusNotFound)
}

func deleteEvent(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.URL.Path[len("/items/"):])
	if err != nil {
		http.Error(w, "Invalid item ID", http.StatusBadRequest)
		return
	}
	for i, item := range items {
		if item.ID == id {
			items = append(items[:i], items[i+1:]...)
			w.WriteHeader(http.StatusNoContent)
			return
		}
	}
	http.Error(w, "Event not found", http.StatusNotFound)
}
