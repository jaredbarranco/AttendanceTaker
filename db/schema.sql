CREATE TABLE IF NOT EXISTS event_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL
);

CREATE TABLE IF NOT EXISTS attendanceStatus_enums (
    attendanceStatus VARCHAR(32) PRIMARY KEY,
    description TEXT
);

CREATE TABLE IF NOT EXISTS persons_standing_enums (
    standing VARCHAR(32) PRIMARY KEY,
    description TEXT
);

INSERT INTO persons_standing_enums (standing, description) VALUES ('contact','A contact person for another person') ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS events (
    id serial NOT NULL,
	name varchar(64) NOT NULL,
	startDateTime TIMESTAMP,
	endDateTime TIMESTAMP,
	location varchar(128), -- Placeholder, may need FK to different types
	type int NOT NULL,
	FOREIGN KEY (type) REFERENCES event_types(id) --Placeholder for FK to 
);
DROP FUNCTION IF EXISTS createevent();
 --- EVENT FUNCTIONS ----
CREATE OR REPLACE FUNCTION create_event(
    event_name VARCHAR,
    event_date_time TIMESTAMP,
    timezone VARCHAR,
    tags TEXT[] DEFAULT NULL,
    event_types TEXT[] DEFAULT NULL,
    event_location TEXT DEFAULT NULL,
    session_id INT DEFAULT NULL,
    required_group_ids INT[] DEFAULT NULL,
    required_person_ids INT[] DEFAULT NULL
) RETURNS INT AS $$
DECLARE
    new_event_id INT;
BEGIN
    INSERT INTO events (eventName, eventDateTime, timezone, tags, eventTypes, eventLocation)
    VALUES (event_name, event_date_time, timezone, tags, event_types, event_location)
    RETURNING id INTO new_event_id;

    IF session_id IS NOT NULL THEN
        INSERT INTO sessions2events (sessionId, eventId)
        VALUES (session_id, new_event_id);
    END IF;

    IF required_group_ids IS NOT NULL THEN
        INSERT INTO events_requiredGroups (eventId, groupId)
        SELECT new_event_id, unnest(required_group_ids);
    END IF;

    IF required_person_ids IS NOT NULL THEN
        INSERT INTO events_requiredPersons (eventId, personId)
        SELECT new_event_id, unnest(required_person_ids);
    END IF;

    RETURN new_event_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION read_event(event_id INT) RETURNS TABLE (
    id INT,
    eventName VARCHAR,
    eventDateTime TIMESTAMP,
    timezone VARCHAR,
    tags TEXT[],
    eventTypes TEXT[],
    eventLocation TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT id, eventName, eventDateTime, timezone, tags, eventTypes, eventLocation
    FROM events
    WHERE id = event_id;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION update_event(
    event_id INT,
    event_name VARCHAR,
    event_date_time TIMESTAMP,
    timezone VARCHAR,
    tags TEXT[] DEFAULT NULL,
    event_types TEXT[] DEFAULT NULL,
    event_location TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE events
    SET eventName = event_name,
        eventDateTime = event_date_time,
        timezone = timezone,
        tags = COALESCE(tags, events.tags),
        eventTypes = COALESCE(event_types, events.eventTypes),
        eventLocation = COALESCE(event_location, events.eventLocation)
    WHERE id = event_id;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION delete_event(event_id INT) RETURNS VOID AS $$
BEGIN
    DELETE FROM events_requiredPersons WHERE eventId = event_id;
    DELETE FROM events_requiredGroups WHERE eventId = event_id;
    DELETE FROM sessions2events WHERE eventId = event_id;
    DELETE FROM events WHERE id = event_id;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION create_person(
    person_name VARCHAR,
    phone VARCHAR DEFAULT NULL,
    email VARCHAR DEFAULT NULL,
    standing VARCHAR DEFAULT NULL
) RETURNS INT AS $$
DECLARE
    new_person_id INT;
BEGIN
    INSERT INTO persons (name, phone, email, standing)
    VALUES (person_name, phone, email, standing)
    RETURNING id INTO new_person_id;

    RETURN new_person_id;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION read_person(person_id INT) RETURNS TABLE (
    id INT,
    name VARCHAR,
    phone VARCHAR,
    email VARCHAR,
    standing VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT id, name, phone, email, standing
    FROM persons
    WHERE id = person_id;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION update_person(
    person_id INT,
    person_name VARCHAR,
    phone VARCHAR DEFAULT NULL,
    email VARCHAR DEFAULT NULL,
    standing VARCHAR DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE persons
    SET name = person_name,
        phone = COALESCE(phone, persons.phone),
        email = COALESCE(email, persons.email),
        standing = COALESCE(standing, persons.standing)
    WHERE id = person_id;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION delete_person(person_id INT) RETURNS VOID AS $$
BEGIN
    DELETE FROM persons2contactPersons WHERE personId = person_id OR contactPersonId = person_id;
    DELETE FROM persons2groups WHERE personId = person_id;
    DELETE FROM events_attendance WHERE personId = person_id;
    DELETE FROM persons WHERE id = person_id;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS persons (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),   -- Assuming phone number length is up to 20 characters
    email VARCHAR(100),  -- Assuming email length is up to 100 characters
    standing VARCHAR(128),
    FOREIGN KEY (standing) REFERENCES persons_standing_enums(standing)
);


CREATE TABLE IF NOT EXISTS groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    description TEXT,    -- Assuming description can be of variable length
   tags TEXT[]          -- Assuming tags is an array of text
);

CREATE OR REPLACE FUNCTION add_person_to_group(
    person_id INT,
    group_name VARCHAR(64)
) RETURNS INT[] AS $$
DECLARE
    _gid INT;
    _return INT[];
BEGIN
    SELECT id into _gid from groups g where g.name = group_name;
    INSERT INTO persons2groups (personId, groupId) VALUES (person_id, _gid);
    SELECT array_agg(groupId) into _return from persons2groups where personId = person_id;
    RETURN _return;
END;
$$ LANGUAGE plpgsql;
CREATE TABLE IF NOT EXISTS persons2groups (
    id SERIAL PRIMARY KEY,
    personId INT NOT NULL,
    groupId INT NOT NULL,
    FOREIGN KEY (personId) REFERENCES persons(id),
    FOREIGN KEY (groupId) REFERENCES groups(id)
);

CREATE TABLE IF NOT EXISTS persons2contactPersons (
    id SERIAL PRIMARY KEY,
    personId INT NOT NULL,
    contactPersonId INT NOT NULL,
    FOREIGN KEY (personId) REFERENCES persons(id),
    FOREIGN KEY (contactPersonId) REFERENCES persons(id)
);

CREATE OR REPLACE FUNCTION check_contactPerson()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT p.standing FROM persons2contactPersons p2c left join persons p on p.id = p2c.contactPersonId WHERE p2c.id = NEW.id) != 'contact' THEN
        RAISE EXCEPTION 'Customer must be of type contact';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_contact_type_trigger
BEFORE INSERT OR UPDATE ON persons2contactPersons
FOR EACH ROW
EXECUTE FUNCTION check_contactPerson();


CREATE TABLE IF NOT EXISTS tags (
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

CREATE TABLE IF NOT EXISTS sessions (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT NOT NULL,
    sessionStartDate TIMESTAMP,
    sessionEndDate TIMESTAMP,
    sessionLocation TEXT
);

CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    eventName VARCHAR NOT NULL,
    eventDateTime TIMESTAMP NOT NULL,
    --orgId INT NOT NULL,
    timezone VARCHAR NOT NULL,
    tags TEXT[],
    eventTypes TEXT[],
    eventLocation TEXT
    --FOREIGN KEY (orgId) REFERENCES Organization(id)
);

CREATE TABLE IF NOT EXISTS sessions2events (
    id SERIAL PRIMARY KEY,
    sessionId INT NOT NULL,
    eventId INT NOT NULL,
    FOREIGN KEY (sessionId) REFERENCES sessions(id),
    FOREIGN KEY (eventId) REFERENCES events(id)
);

CREATE TABLE IF NOT EXISTS events_attendance (
    id SERIAL PRIMARY KEY,
    eventId INT NOT NULL,
    personId INT NOT NULL,
    attendanceStatus VARCHAR(32) NOT NULL,
    FOREIGN KEY (eventId) REFERENCES events(id),
    FOREIGN KEY (personId) REFERENCES persons(id),
    FOREIGN KEY (attendanceStatus) REFERENCES attendanceStatus_enums(attendanceStatus)
);

CREATE OR REPLACE FUNCTION create_attendance(
    event_id INT,
    person_id INT,
    attendance_status VARCHAR
) RETURNS INT AS $$
DECLARE
    new_attendance_id INT;
BEGIN
    INSERT INTO events_attendance (eventId, personId, attendanceStatus)
    VALUES (event_id, person_id, attendance_status)
    RETURNING id INTO new_attendance_id;

    RETURN new_attendance_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_attendance(
    attendance_id INT,
    event_id INT,
    person_id INT,
    attendance_status VARCHAR
) RETURNS VOID AS $$
BEGIN
    UPDATE events_attendance
    SET eventId = event_id,
        personId = person_id,
        attendanceStatus = attendance_status
    WHERE id = attendance_id;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS events_requiredGroups (
    id SERIAL PRIMARY KEY,
    eventId INT NOT NULL,
    groupId INT NOT NULL,
    FOREIGN KEY (eventId) REFERENCES events(id),
    FOREIGN KEY (groupId) REFERENCES groups(id)
);

CREATE TABLE IF NOT EXISTS events_requiredPersons (
    id SERIAL PRIMARY KEY,
    eventId INT NOT NULL,
    personId INT NOT NULL,
    FOREIGN KEY (eventId) REFERENCES events(id),
    FOREIGN KEY (personId) REFERENCES persons(id)
);

