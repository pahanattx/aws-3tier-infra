-- =========================================================
-- TeamOps - Final Database Schema
-- Fresh deployment schema
-- =========================================================

CREATE DATABASE IF NOT EXISTS teamops;
USE teamops;


/* =========================================================
   USERS
========================================================= */

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(100) NOT NULL,

    email VARCHAR(150) NOT NULL UNIQUE,

    password_hash VARCHAR(255) NULL,

    role ENUM(
        'Team Lead',
        'Frontend',
        'Backend',
        'QA',
        'Cloud',
        'Support'
    ) NOT NULL,

    level ENUM(
        'Junior',
        'Mid',
        'Senior'
    ) NOT NULL DEFAULT 'Mid',

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


/* =========================================================
   PROJECTS
========================================================= */

CREATE TABLE projects (
    id INT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(120) NOT NULL,

    description VARCHAR(500) NULL,

    stage ENUM(
        'Development',
        'Maintenance',
        'Archived'
    ) NOT NULL DEFAULT 'Development',

    lead_user_id INT NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (lead_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
);


/* =========================================================
   PROJECT MEMBERS
========================================================= */

CREATE TABLE project_members (
    project_id INT NOT NULL,

    user_id INT NOT NULL,

    PRIMARY KEY (
        project_id,
        user_id
    ),

    FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);


/* =========================================================
   TASKS
========================================================= */

CREATE TABLE tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,

    project_id INT NOT NULL,

    title VARCHAR(200) NOT NULL,

    description TEXT NULL,

    category ENUM(
        'Frontend',
        'Backend',
        'QA',
        'Infrastructure',
        'Support',
        'General'
    ) NOT NULL DEFAULT 'General',

    priority ENUM(
        'low',
        'medium',
        'high',
        'critical'
    ) NOT NULL DEFAULT 'medium',

    status ENUM(
        'open',
        'in_progress',
        'done'
    ) NOT NULL DEFAULT 'open',

    assignee_user_id INT NULL,

    created_by_user_id INT NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE CASCADE,

    FOREIGN KEY (assignee_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    FOREIGN KEY (created_by_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    INDEX idx_tasks_project (
        project_id
    ),

    INDEX idx_tasks_assignee (
        assignee_user_id
    ),

    INDEX idx_tasks_status (
        status
    )
);


/* =========================================================
   INCIDENTS
========================================================= */

CREATE TABLE incidents (
    id INT AUTO_INCREMENT PRIMARY KEY,

    project_id INT NOT NULL,

    title VARCHAR(200) NOT NULL,

    description TEXT NULL,

    category ENUM(
        'Frontend',
        'Backend',
        'QA',
        'Infrastructure',
        'Support',
        'General'
    ) NOT NULL DEFAULT 'General',

    severity ENUM(
        'low',
        'medium',
        'high',
        'critical'
    ) NOT NULL DEFAULT 'medium',

    status ENUM(
        'new',
        'investigating',
        'resolved'
    ) NOT NULL DEFAULT 'new',

    owner_user_id INT NULL,

    reported_by_user_id INT NULL,

    resolution_note TEXT NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    resolved_at TIMESTAMP NULL,

    FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE CASCADE,

    FOREIGN KEY (owner_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    FOREIGN KEY (reported_by_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    INDEX idx_incidents_project (
        project_id
    ),

    INDEX idx_incidents_owner (
        owner_user_id
    ),

    INDEX idx_incidents_status (
        status
    )
);


/* =========================================================
   ACTIVITY LOGS
========================================================= */

CREATE TABLE activity_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,

    project_id INT NULL,

    user_id INT NULL,

    entity_type ENUM(
        'task',
        'incident'
    ) NOT NULL,

    entity_id INT NOT NULL,

    action VARCHAR(1000) NOT NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    INDEX idx_activity_project (
        project_id
    ),

    INDEX idx_activity_user (
        user_id
    ),

    INDEX idx_activity_created (
        created_at
    )
);


/* =========================================================
   AUTH SESSIONS
========================================================= */

CREATE TABLE auth_sessions (
    token_hash CHAR(64) PRIMARY KEY,

    user_id INT NOT NULL,

    expires_at DATETIME NOT NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    INDEX idx_auth_sessions_user (
        user_id
    ),

    INDEX idx_auth_sessions_expires (
        expires_at
    )
);


/* =========================================================
   DEMO USERS

   Password hashes are intentionally NOT stored here.
   Run seed-auth.js after configuring private demo passwords.
========================================================= */

INSERT INTO users (
    id,
    name,
    email,
    role,
    level
)
VALUES
(
    1,
    'Sara Perera',
    'sara@example.com',
    'Team Lead',
    'Senior'
),
(
    2,
    'Maya Silva',
    'maya@example.com',
    'Frontend',
    'Senior'
),
(
    3,
    'Nimal Fernando',
    'nimal@example.com',
    'Frontend',
    'Junior'
),
(
    4,
    'Kasun Jayasuriya',
    'kasun@example.com',
    'Backend',
    'Mid'
),
(
    5,
    'Ravi Senanayake',
    'ravi@example.com',
    'QA',
    'Mid'
),
(
    6,
    'Dilan Perera',
    'dilan@example.com',
    'Cloud',
    'Senior'
);


/* =========================================================
   PROJECTS
========================================================= */

INSERT INTO projects (
    id,
    name,
    description,
    stage,
    lead_user_id
)
VALUES
(
    1,
    'ShopX E-Commerce',
    'Customer-facing e-commerce platform',
    'Maintenance',
    1
),
(
    2,
    'MediCare Portal',
    'Patient and staff web portal',
    'Development',
    1
);


/* =========================================================
   PROJECT MEMBERS
========================================================= */

INSERT INTO project_members (
    project_id,
    user_id
)
VALUES
(1,1),
(1,2),
(1,3),
(1,4),
(1,5),
(1,6),

(2,1),
(2,2),
(2,4),
(2,5);


/* =========================================================
   DEMO TASKS
========================================================= */

INSERT INTO tasks (
    project_id,
    title,
    description,
    category,
    priority,
    status,
    assignee_user_id,
    created_by_user_id
)
VALUES
(
    1,
    'Optimize mobile checkout layout',
    'Improve checkout responsiveness and mobile usability.',
    'Frontend',
    'medium',
    'open',
    2,
    1
),
(
    1,
    'Add payment retry handling',
    'Improve backend handling for failed or delayed payment requests.',
    'Backend',
    'high',
    'open',
    4,
    1
),
(
    1,
    'Run checkout regression tests',
    'Run regression testing for the checkout workflow.',
    'QA',
    'medium',
    'open',
    5,
    1
),
(
    2,
    'Validate appointment API requests',
    'Validate incoming appointment API request data.',
    'Backend',
    'high',
    'open',
    4,
    1
),
(
    2,
    'Improve appointment form',
    'Improve appointment form usability and validation feedback.',
    'Frontend',
    'medium',
    'open',
    2,
    1
);


/* =========================================================
   DEMO INCIDENTS
========================================================= */

INSERT INTO incidents (
    project_id,
    title,
    description,
    category,
    severity,
    status,
    owner_user_id,
    reported_by_user_id
)
VALUES
(
    1,
    'Checkout page intermittently fails to load',
    'Some users report intermittent checkout page loading failures.',
    'Frontend',
    'critical',
    'new',
    2,
    1
),
(
    1,
    'Payment gateway response delay',
    'Payment gateway responses are taking longer than expected.',
    'Backend',
    'high',
    'new',
    4,
    1
),
(
    2,
    'Appointment validation mismatch',
    'Appointment form validation behaviour does not match expected rules.',
    'QA',
    'medium',
    'new',
    5,
    1
);