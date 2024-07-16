CREATE TABLE event_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL
);

CREATE TABLE attendanceStatus_enums (
    attendanceStatus VARCHAR(32) PRIMARY KEY,
    description TEXT
);

CREATE TABLE persons_standing_enums (
    standing VARCHAR(32) PRIMARY KEY,
    description TEXT
);

INSERT INTO persons_standing_enums (standing, description) VALUES ('contact','A contact person for another person') ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS events (
    id serial NOT NULL,
	name varchar(64) NOT NULL,
	startDateTime datetime,
	endDateTime datetime,
	location varchar(128), -- Placeholder, may need FK to different types
	type int NOT NULL,
	FOREIGN KEY (type) REFERENCES event_types(id) --Placeholder for FK to 
);

CREATE TABLE persons (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),   -- Assuming phone number length is up to 20 characters
    email VARCHAR(100),  -- Assuming email length is up to 100 characters
    standing VARCHAR(128),
    FOREIGN KEY (standing) REFERENCES person_standing_enums(standing)
);

CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,    -- Assuming description can be of variable length
   tags TEXT[]          -- Assuming tags is an array of text
);

CREATE TABLE persons2groups (
    id SERIAL PRIMARY KEY,
    personId INT NOT NULL,
    groupId INT NOT NULL,
    FOREIGN KEY (personId) REFERENCES persons(id),
    FOREIGN KEY (groupId) REFERENCES groups(id)
);

CREATE TABLE persons2contactPersons (
    id SERIAL PRIMARY KEY,
    personId INT NOT NULL,
    contactPersonId INT NOT NULL,
    FOREIGN KEY (personId) REFERENCES persons(id),
    FOREIGN KEY (contactPersonId) REFERENCES persons(id),
    CHECK ((SELECT standing FROM persons WHERE personId = contactPersonId) = 'contact')
);
CREATE TABLE tags (
    tagName VARCHAR(32) PRIMARY KEY,
    description TEXT
);
-- Can be handled through postgres schemas - one schema for each org
-- CREATE TABLE Organization (
--     id SERIAL PRIMARY KEY,
--     name VARCHAR NOT NULL,
--     description TEXT NOT NULL,
--     primaryContactPersonId INT NOT NULL,
--     FOREIGN KEY (primaryContactPersonId) REFERENCES Persons(person_id)
-- );

CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT NOT NULL,
    sessionStartDate TIMESTAMP,
    sessionEndDate TIMESTAMP,
    sessionLocation TEXT
);

CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    eventName VARCHAR NOT NULL,
    eventDateTime DATE NOT NULL,
    --orgId INT NOT NULL,
    timezone VARCHAR NOT NULL,
    tags TEXT[],
    eventTypes TEXT[],
    eventLocation TEXT
    --FOREIGN KEY (orgId) REFERENCES Organization(id)
);

CREATE TABLE sessions2events (
    id SERIAL PRIMARY KEY,
    sessionId INT NOT NULL,
    eventId INT NOT NULL,
    FOREIGN KEY (sessionId) REFERENCES sessions(id),
    FOREIGN KEY (eventId) REFERENCES events(id)
);

CREATE TABLE events_attendance (
    id SERIAL PRIMARY KEY,
    eventId INT NOT NULL,
    personId INT NOT NULL,
    attendanceStatus VARCHAR(32) NOT NULL,
    FOREIGN KEY (eventId) REFERENCES events(id),
    FOREIGN KEY (personId) REFERENCES persons(id),
    FOREIGN KEY (attendanceStatus) REFERENCES attendanceStatus_enums(attendanceStatus)
);

CREATE TABLE events_requiredGroups (
    id SERIAL PRIMARY KEY,
    eventId INT NOT NULL,
    groupId INT NOT NULL,
    FOREIGN KEY (eventId) REFERENCES events(id),
    FOREIGN KEY (groupId) REFERENCES groups(id)
);

CREATE TABLE events_requiredPersons (
    id SERIAL PRIMARY KEY,
    eventId INT NOT NULL,
    personId INT NOT NULL,
    FOREIGN KEY (eventId) REFERENCES events(id),
    FOREIGN KEY (personId) REFERENCES persons(id)
);




