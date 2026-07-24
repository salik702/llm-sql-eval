
PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS prereq;
DROP TABLE IF EXISTS teaches;
DROP TABLE IF EXISTS takes;
DROP TABLE IF EXISTS student;
DROP TABLE IF EXISTS instructor;
DROP TABLE IF EXISTS course;
DROP TABLE IF EXISTS department;

PRAGMA foreign_keys = ON;


-- =========================================================
-- TABLES
-- =========================================================

CREATE TABLE department (
    dept_name TEXT PRIMARY KEY,
    building TEXT NOT NULL,
    budget REAL NOT NULL CHECK (budget >= 0)
);


CREATE TABLE course (
    course_id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    dept_name TEXT NOT NULL,
    credits INTEGER NOT NULL CHECK (credits > 0),

    FOREIGN KEY (dept_name)
        REFERENCES department(dept_name)
);


CREATE TABLE instructor (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    dept_name TEXT NOT NULL,
    salary REAL NOT NULL CHECK (salary > 0),

    FOREIGN KEY (dept_name)
        REFERENCES department(dept_name)
);


CREATE TABLE student (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    dept_name TEXT NOT NULL,
    total_credits INTEGER NOT NULL DEFAULT 0
        CHECK (total_credits >= 0),

    FOREIGN KEY (dept_name)
        REFERENCES department(dept_name)
);


CREATE TABLE takes (
    id TEXT NOT NULL,
    course_id TEXT NOT NULL,
    sec_id TEXT NOT NULL,
    semester TEXT NOT NULL
        CHECK (
            semester IN (
                'Spring',
                'Summer',
                'Fall',
                'Winter'
            )
        ),
    year INTEGER NOT NULL,
    grade TEXT,

    PRIMARY KEY (
        id,
        course_id,
        sec_id,
        semester,
        year
    ),

    FOREIGN KEY (id)
        REFERENCES student(id),

    FOREIGN KEY (course_id)
        REFERENCES course(course_id)
);


CREATE TABLE teaches (
    id TEXT NOT NULL,
    course_id TEXT NOT NULL,
    sec_id TEXT NOT NULL,
    semester TEXT NOT NULL
        CHECK (
            semester IN (
                'Spring',
                'Summer',
                'Fall',
                'Winter'
            )
        ),
    year INTEGER NOT NULL,

    PRIMARY KEY (
        id,
        course_id,
        sec_id,
        semester,
        year
    ),

    FOREIGN KEY (id)
        REFERENCES instructor(id),

    FOREIGN KEY (course_id)
        REFERENCES course(course_id)
);


CREATE TABLE prereq (
    course_id TEXT NOT NULL,
    prereq_id TEXT NOT NULL,

    PRIMARY KEY (
        course_id,
        prereq_id
    ),

    FOREIGN KEY (course_id)
        REFERENCES course(course_id),

    FOREIGN KEY (prereq_id)
        REFERENCES course(course_id),

    CHECK (course_id <> prereq_id)
);


-- =========================================================
-- DEPARTMENTS
-- =========================================================

INSERT INTO department VALUES
('Computer Science', 'Lovelace', 1200000),
('Finance', 'Whitman', 900000),
('Mathematics', 'Gauss', 700000),
('Physics', 'Newton', 850000),
('History', 'Taylor', 400000),
('Biology', 'Darwin', 650000),
('Statistics', 'Pearson', 550000),
('Philosophy', 'Aristotle', 300000);


-- =========================================================
-- INSTRUCTORS
-- =========================================================

INSERT INTO instructor VALUES
('10101', 'Srinivasan', 'Computer Science', 95000),
('10202', 'Kim', 'Computer Science', 88000),
('10303', 'Patel', 'Computer Science', 68000),

('12121', 'Wu', 'Finance', 92000),
('12222', 'Mehta', 'Finance', 76000),
('12323', 'Rao', 'Finance', 65000),

('15151', 'Mozart', 'Mathematics', 48000),
('15252', 'Euler', 'Mathematics', 72000),

('22222', 'Einstein', 'Physics', 105000),
('22323', 'Curie', 'Physics', 98000),

('32343', 'El Said', 'History', 45000),

('33456', 'Gold', 'Biology', 62000),
('33557', 'Darwin', 'Biology', 58000),

('44111', 'Fisher', 'Statistics', 85000);


-- Notice:
-- Philosophy intentionally has no instructor.
-- This allows us to test LEFT JOIN and zero-count queries.


-- =========================================================
-- COURSES
-- =========================================================

INSERT INTO course VALUES
('CS-101', 'Introduction to Computer Science', 'Computer Science', 4),
('CS-201', 'Data Structures', 'Computer Science', 4),
('CS-301', 'Database Systems', 'Computer Science', 4),
('CS-315', 'Artificial Intelligence', 'Computer Science', 4),

('FIN-101', 'Introduction to Finance', 'Finance', 3),
('FIN-201', 'Corporate Finance', 'Finance', 3),
('FIN-301', 'Financial Derivatives', 'Finance', 3),

('MATH-101', 'Calculus I', 'Mathematics', 4),
('MATH-201', 'Linear Algebra', 'Mathematics', 4),

('PHY-101', 'Mechanics', 'Physics', 4),
('PHY-201', 'Electromagnetism', 'Physics', 4),

('HIST-101', 'World History', 'History', 3),
('HIST-201', 'Modern History', 'History', 3),

('BIO-101', 'General Biology', 'Biology', 4),
('BIO-201', 'Genetics', 'Biology', 4),

('STAT-101', 'Introduction to Statistics', 'Statistics', 4),
('STAT-201', 'Probability', 'Statistics', 4),

('PHIL-101', 'Introduction to Philosophy', 'Philosophy', 3);


-- =========================================================
-- STUDENTS
-- =========================================================

INSERT INTO student VALUES
('001', 'Alice', 'Computer Science', 64),
('002', 'Bob', 'Finance', 52),
('003', 'Charlie', 'Mathematics', 48),
('004', 'Diana', 'Physics', 55),
('005', 'Eve', 'Computer Science', 60),
('006', 'Frank', 'Finance', 42),
('007', 'Grace', 'Biology', 46),
('008', 'Henry', 'History', 38),
('009', 'Irene', 'Computer Science', 70),
('010', 'Jack', 'Statistics', 58),
('011', 'Karen', 'Physics', 50),
('012', 'Liam', 'Finance', 36),
('013', 'Maya', 'Biology', 40),
('014', 'Noah', 'Mathematics', 54),
('015', 'Olivia', 'Computer Science', 44),
('016', 'Peter', 'History', 34),
('017', 'Quinn', 'Statistics', 62),
('018', 'Riya', 'Philosophy', 28),
('019', 'Sam', 'Computer Science', 32),
('020', 'Tara', 'Finance', 47);


-- =========================================================
-- TEACHING RECORDS
-- =========================================================

INSERT INTO teaches VALUES
('10101', 'CS-101', '1', 'Fall', 2009),
('10101', 'CS-201', '1', 'Spring', 2010),

('10202', 'CS-301', '1', 'Fall', 2010),
('10202', 'CS-315', '1', 'Spring', 2010),
('10202', 'CS-101', '1', 'Spring', 2011),

('10303', 'CS-201', '2', 'Fall', 2009),
('10303', 'CS-301', '1', 'Spring', 2010),

('12121', 'FIN-101', '1', 'Fall', 2009),
('12121', 'FIN-201', '1', 'Spring', 2010),

('12222', 'FIN-101', '1', 'Fall', 2010),

('12323', 'FIN-201', '1', 'Spring', 2011),

('15151', 'MATH-101', '1', 'Fall', 2009),

('15252', 'MATH-201', '1', 'Spring', 2010),
('15252', 'MATH-101', '1', 'Fall', 2010),

('22222', 'PHY-101', '1', 'Fall', 2009),
('22222', 'PHY-201', '1', 'Spring', 2010),

('22323', 'PHY-101', '1', 'Fall', 2010),

('32343', 'HIST-101', '1', 'Fall', 2009),
('32343', 'HIST-201', '1', 'Spring', 2010),

('33456', 'BIO-101', '1', 'Fall', 2009),
('33456', 'BIO-201', '1', 'Spring', 2010),

('33557', 'BIO-101', '1', 'Fall', 2010),

('44111', 'STAT-101', '1', 'Fall', 2009),
('44111', 'STAT-201', '1', 'Spring', 2010);


-- =========================================================
-- STUDENT ENROLMENTS
-- =========================================================

-- CS-101 has 8 enrolments in total.
--
-- The first five students belong to the Fall 2009 offering,
-- taught by instructor 10101.
--
-- The remaining three belong to the Spring 2011 offering,
-- taught by instructor 10202.
--
-- This distinction helps catch incorrect joins that match only
-- on course_id and ignore semester, section and year.

INSERT INTO takes VALUES
('001', 'CS-101', '1', 'Fall', 2009, 'A'),
('005', 'CS-101', '1', 'Fall', 2009, 'B'),
('009', 'CS-101', '1', 'Fall', 2009, 'A'),
('015', 'CS-101', '1', 'Fall', 2009, 'B'),
('019', 'CS-101', '1', 'Fall', 2009, 'A'),

('002', 'CS-101', '1', 'Spring', 2011, 'B'),
('003', 'CS-101', '1', 'Spring', 2011, 'A'),
('004', 'CS-101', '1', 'Spring', 2011, 'C');


-- FIN-101 has 6 enrolments.

INSERT INTO takes VALUES
('002', 'FIN-101', '1', 'Fall', 2009, 'A'),
('006', 'FIN-101', '1', 'Fall', 2009, 'B'),
('012', 'FIN-101', '1', 'Fall', 2009, 'B'),
('020', 'FIN-101', '1', 'Fall', 2009, 'A'),
('008', 'FIN-101', '1', 'Fall', 2009, 'C'),
('016', 'FIN-101', '1', 'Fall', 2009, 'B');


-- MATH-101 has 5 enrolments.

INSERT INTO takes VALUES
('003', 'MATH-101', '1', 'Fall', 2009, 'A'),
('014', 'MATH-101', '1', 'Fall', 2009, 'B'),
('001', 'MATH-101', '1', 'Fall', 2009, 'A'),
('005', 'MATH-101', '1', 'Fall', 2009, 'B'),
('010', 'MATH-101', '1', 'Fall', 2009, 'C');


-- CS-201 has 4 enrolments.

INSERT INTO takes VALUES
('001', 'CS-201', '1', 'Spring', 2010, 'B'),
('005', 'CS-201', '1', 'Spring', 2010, 'A'),
('009', 'CS-201', '1', 'Spring', 2010, 'A'),
('015', 'CS-201', '1', 'Spring', 2010, 'B');


-- CS-301 has 3 enrolments.

INSERT INTO takes VALUES
('001', 'CS-301', '1', 'Fall', 2010, 'A'),
('009', 'CS-301', '1', 'Fall', 2010, 'B'),
('019', 'CS-301', '1', 'Fall', 2010, 'A');


-- FIN-201 has 3 enrolments.

INSERT INTO takes VALUES
('002', 'FIN-201', '1', 'Spring', 2010, 'B'),
('006', 'FIN-201', '1', 'Spring', 2010, 'A'),
('012', 'FIN-201', '1', 'Spring', 2010, 'B');


-- PHY-101 has 3 enrolments.

INSERT INTO takes VALUES
('004', 'PHY-101', '1', 'Fall', 2009, 'A'),
('011', 'PHY-101', '1', 'Fall', 2009, 'B'),
('014', 'PHY-101', '1', 'Fall', 2009, 'C');


-- BIO-101 has 3 enrolments.

INSERT INTO takes VALUES
('007', 'BIO-101', '1', 'Fall', 2009, 'A'),
('013', 'BIO-101', '1', 'Fall', 2009, 'B'),
('011', 'BIO-101', '1', 'Fall', 2009, 'A');


-- MATH-201 has 2 enrolments.

INSERT INTO takes VALUES
('003', 'MATH-201', '1', 'Spring', 2010, 'A'),
('014', 'MATH-201', '1', 'Spring', 2010, 'B');


-- PHY-201 has 2 enrolments.

INSERT INTO takes VALUES
('004', 'PHY-201', '1', 'Spring', 2010, 'B'),
('011', 'PHY-201', '1', 'Spring', 2010, 'A');


-- BIO-201 has 2 enrolments.

INSERT INTO takes VALUES
('007', 'BIO-201', '1', 'Spring', 2010, 'A'),
('013', 'BIO-201', '1', 'Spring', 2010, 'B');


-- HIST-101 has 2 enrolments.

INSERT INTO takes VALUES
('008', 'HIST-101', '1', 'Fall', 2009, 'A'),
('016', 'HIST-101', '1', 'Fall', 2009, 'B');


-- STAT-101 has 2 enrolments.

INSERT INTO takes VALUES
('010', 'STAT-101', '1', 'Fall', 2009, 'A'),
('017', 'STAT-101', '1', 'Fall', 2009, 'B');


-- STAT-201 has 1 enrolment.

INSERT INTO takes VALUES
('010', 'STAT-201', '1', 'Spring', 2010, 'A');


-- These courses intentionally have no enrolments:
--
-- CS-315
-- FIN-301
-- HIST-201
-- PHIL-101


-- =========================================================
-- PREREQUISITES
-- =========================================================

INSERT INTO prereq VALUES
('CS-201', 'CS-101'),
('CS-301', 'CS-201'),
('CS-315', 'CS-201'),

('FIN-201', 'FIN-101'),
('FIN-301', 'FIN-201'),

('MATH-201', 'MATH-101'),

('PHY-201', 'MATH-101'),

('BIO-201', 'BIO-101'),

('STAT-201', 'MATH-101');
