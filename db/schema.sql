CREATE TABLE IF NOT EXISTS events (

	id serial NOT NULL,
	name varchar(64) NOT NULL,
	startDateTime datetime,
	endDateTime datetime,
	location varchar(128), -- Placeholder, may need FK to different types
	type id --Placeholder for FK to 
);

CREATE TABLE persons (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),   -- Assuming phone number length is up to 20 characters
    email VARCHAR(100),  -- Assuming email length is up to 100 characters
    standing VARCHAR(50) -- Assuming standing is a descriptor with up to 50 characters
);

CREATE TABLE Groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,    -- Assuming description can be of variable length
    tags TEXT[]          -- Assuming tags is an array of text
);

CREATE TABLE persons2groups (
    id SERIAL PRIMARY KEY,
    personId INT NOT NULL,
    groupId INT NOT NULL,
    FOREIGN KEY (personId) REFERENCES Persons(person_id),
    FOREIGN KEY (groupId) REFERENCES Groups(id)
);

CREATE TABLE persons2contactPersons (
    id SERIAL PRIMARY KEY,
    personId INT NOT NULL,
    contactPersonId INT NOT NULL,
    FOREIGN KEY (personId) REFERENCES Persons(person_id),
    FOREIGN KEY (contactPersonId) REFERENCES Persons(person_id),
    CHECK ((SELECT standing FROM Persons WHERE person_id = contactPersonId) = 'contact')
);
CREATE TABLE tags (
    tagName VARCHAR(32) PRIMARY KEY,
    description TEXT
);

CREATE TABLE Organization (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT NOT NULL,
    primaryContactPersonId INT NOT NULL,
    FOREIGN KEY (primaryContactPersonId) REFERENCES Persons(person_id)
);

CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT NOT NULL,
    sessionStartDate TIMESTAMP,
    sessionEndDate TIMESTAMP,
    sessionLocation TEXT
);


CREATE TABLE sessions2events (
    id SERIAL PRIMARY KEY,
    sessionId INT NOT NULL,
    eventId INT NOT NULL,
    FOREIGN KEY (sessionId) REFERENCES sessions(id),
    FOREIGN KEY (eventId) REFERENCES Events(eventId)
);


CREATE TABLE Event_Types (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    personId INT NOT NULL,
    attendanceStatus VARCHAR(32) NOT NULL,
    FOREIGN KEY (personId) REFERENCES Persons(person_id),
    FOREIGN KEY (attendanceStatus) REFERENCES attendanceStatus_enums(attendanceStatus)
);

CREATE TABLE Events (
    eventId SERIAL PRIMARY KEY,
    eventName VARCHAR NOT NULL,
    eventDateTime DATE NOT NULL,
    orgId INT NOT NULL,
    timezone VARCHAR NOT NULL,
    tags TEXT[],
    eventTypes TEXT[],
    eventLocation TEXT,
    FOREIGN KEY (orgId) REFERENCES Organization(id)
);


CREATE TABLE Events_Attendance (
    id SERIAL PRIMARY KEY,
    eventId INT NOT NULL,
    personId INT NOT NULL,
    attendanceStatus VARCHAR(32) NOT NULL,
    FOREIGN KEY (eventId) REFERENCES Events(eventId),
    FOREIGN KEY (personId) REFERENCES Persons(person_id),
    FOREIGN KEY (attendanceStatus) REFERENCES attendanceStatus_enums(attendanceStatus)
);

CREATE TABLE Events_RequiredGroups (
    id SERIAL PRIMARY KEY,
    eventId INT NOT NULL,
    groupId INT NOT NULL,
    FOREIGN KEY (eventId) REFERENCES Events(eventId),
    FOREIGN KEY (groupId) REFERENCES Groups(id)
);

CREATE TABLE Events_RequiredPersons (
    id SERIAL PRIMARY KEY,
    eventId INT NOT NULL,
    personId INT NOT NULL,
    FOREIGN KEY (eventId) REFERENCES Events(eventId),
    FOREIGN KEY (personId) REFERENCES Persons(person_id)
);

CREATE TABLE Event_Type_Requirements (
    id SERIAL PRIMARY KEY,
    typeId INT NOT NULL,
    personId INT NOT NULL,
    attendanceStatus VARCHAR(32) NOT NULL,
    FOREIGN KEY (typeId) REFERENCES Event_Types(id),
    FOREIGN KEY (personId) REFERENCES Persons(person_id),
    FOREIGN KEY (attendanceStatus) REFERENCES attendanceStatus_enums(attendanceStatus)
);


CREATE TABLE attendanceStatus_enums (
    attendanceStatus VARCHAR(32) PRIMARY KEY,
    description TEXT
);

