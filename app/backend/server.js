require("dotenv").config();

const express = require("express");
const path = require("path");
const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const pool = require("./db");

const app = express();
const PORT = Number(process.env.PORT || 4000);
const COOKIE_NAME = "teamops_session";
const SESSION_HOURS = 12;
const APP_VERSION = "teamops-flow-v4";

const VALID_CATEGORIES = ["Frontend", "Backend", "QA", "Infrastructure", "Support", "General"];
const VALID_LEVELS = ["low", "medium", "high", "critical"];

const CATEGORY_ROLE = {
  Frontend: "Frontend",
  Backend: "Backend",
  QA: "QA",
  Infrastructure: "Cloud",
  Support: "Support"
};

app.disable("x-powered-by");

app.use(
  express.json({
    limit: "100kb"
  })
);

app.use((req, res, next) => {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader(
    "Permissions-Policy",
    "camera=(), microphone=(), geolocation=()"
  );

  next();
});

app.use(
  express.static(
    path.join(
      __dirname,
      "../frontend"
    )
  )
);


/* =====================================================
   HELPERS
===================================================== */

function cleanText(
  value,
  max = 5000
) {
  return String(
    value ?? ""
  )
    .trim()
    .slice(
      0,
      max
    );
}


function nullableId(value) {
  if (
    value === null ||
    value === "" ||
    value === undefined
  ) {
    return null;
  }

  const id =
    Number(value);

  return (
    Number.isInteger(id) &&
    id > 0
  )
    ? id
    : NaN;
}


function parseCookies(req) {
  const cookies = {};

  for (
    const part of
    String(
      req.headers.cookie || ""
    ).split(";")
  ) {
    const index =
      part.indexOf("=");

    if (
      index < 0
    ) {
      continue;
    }

    cookies[
      part
        .slice(
          0,
          index
        )
        .trim()
    ] =
      decodeURIComponent(
        part
          .slice(
            index + 1
          )
          .trim()
      );
  }

  return cookies;
}


function hashToken(token) {
  return crypto
    .createHash("sha256")
    .update(token)
    .digest("hex");
}


function setSessionCookie(
  res,
  token
) {
  const secure =
    process.env.COOKIE_SECURE === "true"
      ?
      "; Secure"
      :
      "";

  res.setHeader(
    "Set-Cookie",
    `${COOKIE_NAME}=${encodeURIComponent(token)}; HttpOnly; SameSite=Lax; Path=/; Max-Age=${SESSION_HOURS * 3600}${secure}`
  );
}


function clearSessionCookie(res) {
  const secure =
    process.env.COOKIE_SECURE === "true"
      ?
      "; Secure"
      :
      "";

  res.setHeader(
    "Set-Cookie",
    `${COOKIE_NAME}=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0${secure}`
  );
}


function roleMatchesCategory(
  category,
  role
) {
  if (
    role ===
    "Team Lead"
  ) {
    return true;
  }

  if (
    category ===
    "General"
  ) {
    return true;
  }

  return (
    CATEGORY_ROLE[category] ===
    role
  );
}


function assignmentRule(category) {
  if (
    category ===
    "General"
  ) {
    return "any active project member";
  }

  return CATEGORY_ROLE[category]
    ?
    `${CATEGORY_ROLE[category]} or Team Lead`
    :
    "an eligible project member";
}


async function getSessionUser(req) {
  const token =
    parseCookies(
      req
    )[COOKIE_NAME];

  if (
    !token
  ) {
    return null;
  }

  const [rows] =
    await pool.query(
      `
      SELECT
        u.id,
        u.name,
        u.email,
        u.role,
        u.level,
        u.is_active

      FROM auth_sessions s

      JOIN users u
        ON u.id = s.user_id

      WHERE
        s.token_hash = ?
        AND s.expires_at > NOW()
        AND u.is_active = TRUE

      LIMIT 1
      `,
      [
        hashToken(token)
      ]
    );

  return (
    rows[0] ||
    null
  );
}


async function requireAuth(
  req,
  res,
  next
) {
  try {
    const user =
      await getSessionUser(
        req
      );

    if (
      !user
    ) {
      return res
        .status(401)
        .json({
          error:
            "Authentication required"
        });
    }

    req.user =
      user;

    next();
  }
  catch (error) {
    console.error(error);

    res
      .status(500)
      .json({
        error:
          "Authentication check failed"
      });
  }
}


function requireTeamLead(
  req,
  res,
  next
) {
  if (
    !req.user ||
    req.user.role !==
    "Team Lead"
  ) {
    return res
      .status(403)
      .json({
        error:
          "Team Lead permission required"
      });
  }

  next();
}


async function getProject(projectId) {
  const [rows] =
    await pool.query(
      `
      SELECT
        id,
        name,
        stage

      FROM projects

      WHERE id = ?

      LIMIT 1
      `,
      [
        projectId
      ]
    );

  return (
    rows[0] ||
    null
  );
}


async function getProjectMember(
  projectId,
  userId
) {
  if (
    !Number.isInteger(
      userId
    )
  ) {
    return null;
  }

  const [rows] =
    await pool.query(
      `
      SELECT
        u.id,
        u.name,
        u.role,
        u.level

      FROM project_members pm

      JOIN users u
        ON u.id = pm.user_id

      WHERE
        pm.project_id = ?
        AND pm.user_id = ?
        AND u.is_active = TRUE

      LIMIT 1
      `,
      [
        projectId,
        userId
      ]
    );

  return (
    rows[0] ||
    null
  );
}


async function getEligibleMember(
  projectId,
  userId,
  category
) {
  const member =
    await getProjectMember(
      projectId,
      userId
    );

  return (
    member &&
    roleMatchesCategory(
      category,
      member.role
    )
  )
    ?
    member
    :
    null;
}


async function logActivity(
  projectId,
  userId,
  entityType,
  entityId,
  action
) {
  await pool.query(
    `
    INSERT INTO activity_logs(
      project_id,
      user_id,
      entity_type,
      entity_id,
      action
    )

    VALUES(
      ?,
      ?,
      ?,
      ?,
      ?
    )
    `,
    [
      projectId,
      userId,
      entityType,
      entityId,
      action
    ]
  );
}


/* =====================================================
   FRONTEND / HEALTH
===================================================== */

app.get(
  "/",
  (req, res) => {
    res.sendFile(
      path.join(
        __dirname,
        "../frontend/index.html"
      )
    );
  }
);


app.get(
  "/api/health",
  async (
    req,
    res
  ) => {
    try {
      const [rows] =
        await pool.query(
          `
          SELECT
            VERSION() AS version
          `
        );

      res.json({
        status:
          "healthy",

        database:
          "connected",

        version:
          rows[0].version,

        app_version:
          APP_VERSION
      });
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          status:
            "unhealthy",

          database:
            "disconnected",

          app_version:
            APP_VERSION
        });
    }
  }
);


/* =====================================================
   AUTH
===================================================== */

app.post(
  "/api/auth/login",
  async (
    req,
    res
  ) => {
    try {
      const email =
        cleanText(
          req.body.email,
          320
        )
          .toLowerCase();

      const password =
        String(
          req.body.password ||
          ""
        );

      if (
        !email ||
        !password
      ) {
        return res
          .status(400)
          .json({
            error:
              "Email and password are required"
          });
      }

      const [users] =
        await pool.query(
          `
          SELECT
            id,
            name,
            email,
            role,
            level,
            is_active,
            password_hash

          FROM users

          WHERE
            LOWER(email) = ?

          LIMIT 1
          `,
          [
            email
          ]
        );

      const user =
        users[0];

      if (
        !user ||
        !user.is_active ||
        !user.password_hash
      ) {
        return res
          .status(401)
          .json({
            error:
              "Invalid email or password"
          });
      }

      const validPassword =
        await bcrypt.compare(
          password,
          user.password_hash
        );

      if (
        !validPassword
      ) {
        return res
          .status(401)
          .json({
            error:
              "Invalid email or password"
          });
      }

      await pool.query(
        `
        DELETE FROM auth_sessions
        WHERE expires_at <= NOW()
        `
      );

      await pool.query(
        `
        DELETE FROM auth_sessions
        WHERE user_id = ?
        `,
        [
          user.id
        ]
      );

      const token =
        crypto
          .randomBytes(32)
          .toString("hex");

      const expiresAt =
        new Date(
          Date.now()
          +
          SESSION_HOURS
          *
          3600
          *
          1000
        );

      await pool.query(
        `
        INSERT INTO auth_sessions(
          token_hash,
          user_id,
          expires_at
        )

        VALUES(
          ?,
          ?,
          ?
        )
        `,
        [
          hashToken(token),
          user.id,
          expiresAt
        ]
      );

      setSessionCookie(
        res,
        token
      );

      res.json({
        user: {
          id:
            user.id,

          name:
            user.name,

          email:
            user.email,

          role:
            user.role,

          level:
            user.level
        }
      });
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Login failed"
        });
    }
  }
);


app.get(
  "/api/auth/me",
  requireAuth,
  (
    req,
    res
  ) => {
    res.json({
      user:
        req.user
    });
  }
);


app.post(
  "/api/auth/logout",
  async (
    req,
    res
  ) => {
    try {
      const token =
        parseCookies(
          req
        )[COOKIE_NAME];

      if (
        token
      ) {
        await pool.query(
          `
          DELETE FROM auth_sessions

          WHERE token_hash = ?
          `,
          [
            hashToken(token)
          ]
        );
      }
    }
    catch (error) {
      console.error(error);
    }

    clearSessionCookie(
      res
    );

    res.json({
      message:
        "Logged out"
    });
  }
);


/* =====================================================
   PROJECTS / USERS
===================================================== */

app.get(
  "/api/projects",
  requireAuth,
  async (
    req,
    res
  ) => {
    try {
      let sql =
        `
        SELECT
          p.id,
          p.name,
          p.description,
          p.stage,
          u.name AS lead

        FROM projects p

        LEFT JOIN users u
          ON u.id = p.lead_user_id
        `;

      const params = [];

      if (
        req.user.role !==
        "Team Lead"
      ) {
        sql +=
          `
          WHERE EXISTS(
            SELECT 1

            FROM project_members pm

            WHERE
              pm.project_id = p.id
              AND pm.user_id = ?
          )
          `;

        params.push(
          req.user.id
        );
      }

      sql +=
        `
        ORDER BY p.id
        `;

      const [rows] =
        await pool.query(
          sql,
          params
        );

      res.json(rows);
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to load projects"
        });
    }
  }
);


app.get(
  "/api/projects/:id/members",
  requireAuth,
  async (
    req,
    res
  ) => {
    try {
      const projectId =
        Number(
          req.params.id
        );

      if (
        !Number.isInteger(
          projectId
        ) ||
        projectId <= 0
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid project"
          });
      }

      if (
        req.user.role !==
        "Team Lead" &&
        !await getProjectMember(
          projectId,
          req.user.id
        )
      ) {
        return res
          .status(403)
          .json({
            error:
              "You do not have access to this project"
          });
      }

      const [rows] =
        await pool.query(
          `
          SELECT
            u.id,
            u.name,
            u.role,
            u.level

          FROM project_members pm

          JOIN users u
            ON u.id = pm.user_id

          WHERE
            pm.project_id = ?
            AND u.is_active = TRUE

          ORDER BY
            CASE u.role
              WHEN 'Team Lead'
              THEN 1
              ELSE 2
            END,
            u.name
          `,
          [
            projectId
          ]
        );

      res.json(rows);
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to load project members"
        });
    }
  }
);


app.get(
  "/api/users",
  requireAuth,
  requireTeamLead,
  async (
    req,
    res
  ) => {
    try {
      const [rows] =
        await pool.query(
          `
          SELECT
            id,
            name,
            email,
            role,
            level,
            is_active

          FROM users

          WHERE
            is_active = TRUE

          ORDER BY name
          `
        );

      res.json(rows);
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to load users"
        });
    }
  }
);


/* =====================================================
   TASKS
===================================================== */

app.get(
  "/api/tasks",
  requireAuth,
  async (
    req,
    res
  ) => {
    try {
      let sql =
        `
        SELECT
          t.id,
          t.title,
          t.description,
          t.category,
          t.priority,
          t.status,
          t.created_at,
          t.updated_at,

          p.id AS project_id,
          p.name AS project_name,
          p.stage AS project_stage,

          a.id AS assignee_id,
          a.name AS assignee_name,
          a.role AS assignee_role,
          a.level AS assignee_level,

          c.name AS creator_name

        FROM tasks t

        JOIN projects p
          ON p.id = t.project_id

        LEFT JOIN users a
          ON a.id = t.assignee_user_id

        LEFT JOIN users c
          ON c.id = t.created_by_user_id
        `;

      const params = [];

      if (
        req.user.role !==
        "Team Lead"
      ) {
        sql +=
          `
          WHERE
            t.assignee_user_id = ?
          `;

        params.push(
          req.user.id
        );
      }

      sql +=
        `
        ORDER BY
          t.created_at DESC
        `;

      const [rows] =
        await pool.query(
          sql,
          params
        );

      res.json(rows);
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to load tasks"
        });
    }
  }
);


app.post(
  "/api/tasks",
  requireAuth,
  requireTeamLead,
  async (
    req,
    res
  ) => {
    try {
      const projectId =
        Number(
          req.body.project_id
        );

      const title =
        cleanText(
          req.body.title,
          200
        );

      const description =
        cleanText(
          req.body.description,
          5000
        );

      const category =
        cleanText(
          req.body.category ||
          "General",
          50
        );

      const priority =
        cleanText(
          req.body.priority ||
          "medium",
          20
        );

      const assigneeId =
        nullableId(
          req.body.assignee_user_id
        );

      if (
        !Number.isInteger(
          projectId
        ) ||
        projectId <= 0 ||
        !title
      ) {
        return res
          .status(400)
          .json({
            error:
              "Project and title are required"
          });
      }

      if (
        !VALID_CATEGORIES.includes(
          category
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid task category"
          });
      }

      if (
        !VALID_LEVELS.includes(
          priority
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid task priority"
          });
      }

      if (
        Number.isNaN(
          assigneeId
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid assignee"
          });
      }

      const project =
        await getProject(
          projectId
        );

      if (
        !project
      ) {
        return res
          .status(404)
          .json({
            error:
              "Project not found"
          });
      }

      if (
        project.stage ===
        "Archived"
      ) {
        return res
          .status(400)
          .json({
            error:
              "Tasks cannot be created for archived projects"
          });
      }

      if (
        assigneeId !== null &&
        !await getEligibleMember(
          projectId,
          assigneeId,
          category
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              `${category} tasks can only be assigned to ${assignmentRule(category)}`
          });
      }

      const [result] =
        await pool.query(
          `
          INSERT INTO tasks(
            project_id,
            title,
            description,
            category,
            priority,
            status,
            assignee_user_id,
            created_by_user_id
          )

          VALUES(
            ?,
            ?,
            ?,
            ?,
            ?,
            'open',
            ?,
            ?
          )
          `,
          [
            projectId,
            title,
            description || null,
            category,
            priority,
            assigneeId,
            req.user.id
          ]
        );

      await logActivity(
        projectId,
        req.user.id,
        "task",
        result.insertId,
        `Created task: ${title}`
      );

      res
        .status(201)
        .json({
          message:
            "Task created",

          task_id:
            result.insertId
        });
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to create task"
        });
    }
  }
);


app.patch(
  "/api/tasks/:id",
  requireAuth,
  async (
    req,
    res
  ) => {
    try {
      const taskId =
        Number(
          req.params.id
        );

      if (
        !Number.isInteger(
          taskId
        ) ||
        taskId <= 0
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid task"
          });
      }

      const {
        status,
        title,
        description,
        category,
        priority,
        assignee_user_id
      } = req.body;

      const [rows] =
        await pool.query(
          `
          SELECT
            t.id,
            t.project_id,
            t.title,
            t.description,
            t.category,
            t.priority,
            t.status,
            t.assignee_user_id,

            p.stage AS project_stage,

            a.name AS assignee_name

          FROM tasks t

          JOIN projects p
            ON p.id = t.project_id

          LEFT JOIN users a
            ON a.id = t.assignee_user_id

          WHERE
            t.id = ?

          LIMIT 1
          `,
          [
            taskId
          ]
        );

      const task =
        rows[0];

      if (
        !task
      ) {
        return res
          .status(404)
          .json({
            error:
              "Task not found"
          });
      }

      if (
        task.project_stage ===
        "Archived"
      ) {
        return res
          .status(400)
          .json({
            error:
              "Archived projects are read-only"
          });
      }

      if (
        task.status ===
        "done"
      ) {
        return res
          .status(400)
          .json({
            error:
              "Completed tasks are read-only"
          });
      }

      const isLead =
        req.user.role ===
        "Team Lead";

      const isAssignee =
        Number(
          task.assignee_user_id
        ) ===
        Number(
          req.user.id
        );

      const adminFieldsPresent = [
        title,
        description,
        category,
        priority,
        assignee_user_id
      ]
        .some(
          value =>
            value !== undefined
        );

      if (
        status !== undefined &&
        adminFieldsPresent
      ) {
        return res
          .status(400)
          .json({
            error:
              "Change task status separately from task management"
          });
      }


      /* MEMBER STATUS FLOW */

      if (
        status !== undefined
      ) {
        if (
          !isAssignee
        ) {
          return res
            .status(403)
            .json({
              error:
                "Only the assigned user can change task status"
            });
        }

        const validTransition =
          (
            task.status ===
            "open" &&
            status ===
            "in_progress"
          )
          ||
          (
            task.status ===
            "in_progress" &&
            status ===
            "done"
          );

        if (
          !validTransition
        ) {
          return res
            .status(400)
            .json({
              error:
                `Invalid task transition: ${task.status} -> ${status}`
            });
        }

        await pool.query(
          `
          UPDATE tasks

          SET status = ?

          WHERE id = ?
          `,
          [
            status,
            taskId
          ]
        );

        await logActivity(
          task.project_id,
          req.user.id,
          "task",
          taskId,
          `Task "${task.title}" changed to ${status.replace("_", " ")}`
        );

        return res.json({
          message:
            "Task status updated"
        });
      }


      if (
        !isLead
      ) {
        return res
          .status(403)
          .json({
            error:
              "Team Lead permission required"
          });
      }


      /*
        Once a task has started, its agreed work definition is locked.
        Team Lead may still change priority or reassign it.
      */

      if (
        task.status ===
        "in_progress"
      ) {
        const coreChangeRequested =
          (
            title !== undefined &&
            cleanText(
              title,
              200
            ) !== task.title
          )
          ||
          (
            description !== undefined &&
            cleanText(
              description,
              5000
            ) !==
            (
              task.description ||
              ""
            )
          )
          ||
          (
            category !== undefined &&
            cleanText(
              category,
              50
            ) !== task.category
          );

        if (
          coreChangeRequested
        ) {
          return res
            .status(400)
            .json({
              error:
                "Title, description and category are locked after a task has started. Reassign or change priority only."
            });
        }
      }


      const nextCategory =
        category === undefined
          ?
          task.category
          :
          cleanText(
            category,
            50
          );

      if (
        !VALID_CATEGORIES.includes(
          nextCategory
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid task category"
          });
      }

      const nextAssigneeId =
        assignee_user_id === undefined
          ?
          nullableId(
            task.assignee_user_id
          )
          :
          nullableId(
            assignee_user_id
          );

      if (
        Number.isNaN(
          nextAssigneeId
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid assignee"
          });
      }

      let nextAssigneeName =
        task.assignee_name ||
        null;

      if (
        nextAssigneeId !== null
      ) {
        const member =
          await getEligibleMember(
            task.project_id,
            nextAssigneeId,
            nextCategory
          );

        if (
          !member
        ) {
          return res
            .status(400)
            .json({
              error:
                `${nextCategory} tasks can only be assigned to ${assignmentRule(nextCategory)}`
            });
        }

        nextAssigneeName =
          member.name;
      }
      else {
        nextAssigneeName =
          null;
      }

      const updates = [];
      const values = [];
      const changes = [];

      if (
        title !== undefined
      ) {
        const value =
          cleanText(
            title,
            200
          );

        if (
          !value
        ) {
          return res
            .status(400)
            .json({
              error:
                "Task title cannot be empty"
            });
        }

        if (
          value !==
          task.title
        ) {
          updates.push(
            "title=?"
          );

          values.push(
            value
          );

          changes.push(
            `title "${task.title}" -> "${value}"`
          );
        }
      }

      if (
        description !== undefined
      ) {
        const value =
          cleanText(
            description,
            5000
          );

        if (
          value !==
          (
            task.description ||
            ""
          )
        ) {
          updates.push(
            "description=?"
          );

          values.push(
            value ||
            null
          );

          changes.push(
            "description updated"
          );
        }
      }

      if (
        category !== undefined &&
        nextCategory !==
        task.category
      ) {
        updates.push(
          "category=?"
        );

        values.push(
          nextCategory
        );

        changes.push(
          `category ${task.category} -> ${nextCategory}`
        );
      }

      if (
        priority !== undefined
      ) {
        const value =
          cleanText(
            priority,
            20
          );

        if (
          !VALID_LEVELS.includes(
            value
          )
        ) {
          return res
            .status(400)
            .json({
              error:
                "Invalid task priority"
            });
        }

        if (
          value !==
          task.priority
        ) {
          updates.push(
            "priority=?"
          );

          values.push(
            value
          );

          changes.push(
            `priority ${task.priority} -> ${value}`
          );
        }
      }

      const oldAssigneeId =
        nullableId(
          task.assignee_user_id
        );

      if (
        assignee_user_id !== undefined &&
        nextAssigneeId !==
        oldAssigneeId
      ) {
        updates.push(
          "assignee_user_id=?"
        );

        values.push(
          nextAssigneeId
        );

        changes.push(
          `assignee ${task.assignee_name || "Unassigned"} -> ${nextAssigneeName || "Unassigned"}`
        );

        if (
          task.status ===
          "in_progress"
        ) {
          updates.push(
            "status='open'"
          );

          changes.push(
            "status reset to open"
          );
        }
      }

      if (
        !updates.length
      ) {
        return res.json({
          message:
            "No task changes"
        });
      }

      values.push(
        taskId
      );

      await pool.query(
        `
        UPDATE tasks

        SET
          ${updates.join(", ")}

        WHERE id = ?
        `,
        values
      );

      await logActivity(
        task.project_id,
        req.user.id,
        "task",
        taskId,
        `Task "${task.title}" updated: ${changes.join("; ")}`
      );

      res.json({
        message:
          "Task updated"
      });
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to update task"
        });
    }
  }
);


app.delete(
  "/api/tasks/:id",
  requireAuth,
  requireTeamLead,
  async (
    req,
    res
  ) => {
    try {
      const taskId =
        Number(
          req.params.id
        );

      const [rows] =
        await pool.query(
          `
          SELECT
            t.id,
            t.project_id,
            t.title,
            t.status,

            p.stage AS project_stage

          FROM tasks t

          JOIN projects p
            ON p.id = t.project_id

          WHERE
            t.id = ?

          LIMIT 1
          `,
          [
            taskId
          ]
        );

      const task =
        rows[0];

      if (
        !task
      ) {
        return res
          .status(404)
          .json({
            error:
              "Task not found"
          });
      }

      if (
        task.project_stage ===
        "Archived"
      ) {
        return res
          .status(400)
          .json({
            error:
              "Archived projects are read-only"
          });
      }

      if (
        task.status ===
        "done"
      ) {
        return res
          .status(400)
          .json({
            error:
              "Completed tasks are retained as work history and cannot be deleted"
          });
      }

      await pool.query(
        `
        DELETE FROM tasks

        WHERE id = ?
        `,
        [
          taskId
        ]
      );

      await logActivity(
        task.project_id,
        req.user.id,
        "task",
        taskId,
        `Deleted task: "${task.title}"`
      );

      res
        .status(204)
        .send();
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to delete task"
        });
    }
  }
);


/* =====================================================
   INCIDENTS
===================================================== */

app.get(
  "/api/incidents",
  requireAuth,
  async (
    req,
    res
  ) => {
    try {
      let sql =
        `
        SELECT
          i.id,
          i.title,
          i.description,
          i.category,
          i.severity,
          i.status,
          i.resolution_note,
          i.created_at,
          i.updated_at,
          i.resolved_at,

          p.id AS project_id,
          p.name AS project_name,
          p.stage AS project_stage,

          o.id AS owner_id,
          o.name AS owner_name,
          o.role AS owner_role,
          o.level AS owner_level,

          r.name AS reporter_name

        FROM incidents i

        JOIN projects p
          ON p.id = i.project_id

        LEFT JOIN users o
          ON o.id = i.owner_user_id

        LEFT JOIN users r
          ON r.id = i.reported_by_user_id
        `;

      const params = [];

      if (
        req.user.role !==
        "Team Lead"
      ) {
        sql +=
          `
          WHERE
            i.owner_user_id = ?
          `;

        params.push(
          req.user.id
        );
      }

      sql +=
        `
        ORDER BY
          i.created_at DESC
        `;

      const [rows] =
        await pool.query(
          sql,
          params
        );

      res.json(rows);
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to load incidents"
        });
    }
  }
);


app.post(
  "/api/incidents",
  requireAuth,
  requireTeamLead,
  async (
    req,
    res
  ) => {
    try {
      const projectId =
        Number(
          req.body.project_id
        );

      const title =
        cleanText(
          req.body.title,
          200
        );

      const description =
        cleanText(
          req.body.description,
          5000
        );

      const category =
        cleanText(
          req.body.category ||
          "General",
          50
        );

      const severity =
        cleanText(
          req.body.severity ||
          "medium",
          20
        );

      const ownerId =
        nullableId(
          req.body.owner_user_id
        );

      if (
        !Number.isInteger(
          projectId
        ) ||
        projectId <= 0 ||
        !title
      ) {
        return res
          .status(400)
          .json({
            error:
              "Project and title are required"
          });
      }

      if (
        !VALID_CATEGORIES.includes(
          category
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid incident category"
          });
      }

      if (
        !VALID_LEVELS.includes(
          severity
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid incident severity"
          });
      }

      if (
        Number.isNaN(
          ownerId
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid owner"
          });
      }

      const project =
        await getProject(
          projectId
        );

      if (
        !project
      ) {
        return res
          .status(404)
          .json({
            error:
              "Project not found"
          });
      }

      if (
        project.stage ===
        "Archived"
      ) {
        return res
          .status(400)
          .json({
            error:
              "Incidents cannot be created for archived projects"
          });
      }

      if (
        ownerId !== null &&
        !await getEligibleMember(
          projectId,
          ownerId,
          category
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              `${category} incidents can only be assigned to ${assignmentRule(category)}`
          });
      }

      const [result] =
        await pool.query(
          `
          INSERT INTO incidents(
            project_id,
            title,
            description,
            category,
            severity,
            status,
            owner_user_id,
            reported_by_user_id
          )

          VALUES(
            ?,
            ?,
            ?,
            ?,
            ?,
            'new',
            ?,
            ?
          )
          `,
          [
            projectId,
            title,
            description || null,
            category,
            severity,
            ownerId,
            req.user.id
          ]
        );

      await logActivity(
        projectId,
        req.user.id,
        "incident",
        result.insertId,
        `Created incident: ${title}`
      );

      res
        .status(201)
        .json({
          message:
            "Incident created",

          incident_id:
            result.insertId
        });
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to create incident"
        });
    }
  }
);


app.patch(
  "/api/incidents/:id",
  requireAuth,
  async (
    req,
    res
  ) => {
    try {
      const incidentId =
        Number(
          req.params.id
        );

      if (
        !Number.isInteger(
          incidentId
        ) ||
        incidentId <= 0
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid incident"
          });
      }

      const {
        status,
        resolution_note,
        title,
        description,
        category,
        severity,
        owner_user_id
      } = req.body;

      const [rows] =
        await pool.query(
          `
          SELECT
            i.id,
            i.project_id,
            i.title,
            i.description,
            i.category,
            i.severity,
            i.status,
            i.owner_user_id,

            p.stage AS project_stage,

            o.name AS owner_name

          FROM incidents i

          JOIN projects p
            ON p.id = i.project_id

          LEFT JOIN users o
            ON o.id = i.owner_user_id

          WHERE
            i.id = ?

          LIMIT 1
          `,
          [
            incidentId
          ]
        );

      const incident =
        rows[0];

      if (
        !incident
      ) {
        return res
          .status(404)
          .json({
            error:
              "Incident not found"
          });
      }

      if (
        incident.project_stage ===
        "Archived"
      ) {
        return res
          .status(400)
          .json({
            error:
              "Archived projects are read-only"
          });
      }

      if (
        incident.status ===
        "resolved"
      ) {
        return res
          .status(400)
          .json({
            error:
              "Resolved incidents are read-only"
          });
      }

      const isLead =
        req.user.role ===
        "Team Lead";

      const isOwner =
        Number(
          incident.owner_user_id
        ) ===
        Number(
          req.user.id
        );

      const adminFieldsPresent = [
        title,
        description,
        category,
        severity,
        owner_user_id
      ]
        .some(
          value =>
            value !== undefined
        );

      if (
        status !== undefined &&
        adminFieldsPresent
      ) {
        return res
          .status(400)
          .json({
            error:
              "Change incident status separately from incident management"
          });
      }


      /* OWNER / LEAD STATUS FLOW */

      if (
        status !== undefined
      ) {
        if (
          status ===
          "investigating"
        ) {
          if (
            !isOwner
          ) {
            return res
              .status(403)
              .json({
                error:
                  "Only the assigned owner can start investigation"
              });
          }

          if (
            incident.status !==
            "new"
          ) {
            return res
              .status(400)
              .json({
                error:
                  `Invalid incident transition: ${incident.status} -> investigating`
              });
          }

          await pool.query(
            `
            UPDATE incidents

            SET
              status='investigating',
              resolution_note=NULL,
              resolved_at=NULL

            WHERE id=?
            `,
            [
              incidentId
            ]
          );

          await logActivity(
            incident.project_id,
            req.user.id,
            "incident",
            incidentId,
            `Incident "${incident.title}" changed to investigating`
          );

          return res.json({
            message:
              "Incident moved to investigating"
          });
        }


        if (
          status ===
          "resolved"
        ) {
          const note =
            cleanText(
              resolution_note,
              5000
            );

          if (
            !note
          ) {
            return res
              .status(400)
              .json({
                error:
                  "Resolution note is required when resolving an incident"
              });
          }

          if (
            !isLead
          ) {
            if (
              !isOwner
            ) {
              return res
                .status(403)
                .json({
                  error:
                    "Only the assigned owner can resolve this incident"
                });
            }

            if (
              incident.status !==
              "investigating"
            ) {
              return res
                .status(400)
                .json({
                  error:
                    "Investigate the incident before resolving it"
                });
            }
          }
          else if (
            ![
              "new",
              "investigating"
            ]
              .includes(
                incident.status
              )
          ) {
            return res
              .status(400)
              .json({
                error:
                  `Invalid incident transition: ${incident.status} -> resolved`
              });
          }

          await pool.query(
            `
            UPDATE incidents

            SET
              status='resolved',
              resolution_note=?,
              resolved_at=NOW()

            WHERE id=?
            `,
            [
              note,
              incidentId
            ]
          );

          await logActivity(
            incident.project_id,
            req.user.id,
            "incident",
            incidentId,
            `Incident "${incident.title}" resolved`
          );

          return res.json({
            message:
              "Incident resolved"
          });
        }


        return res
          .status(400)
          .json({
            error:
              "Invalid incident status transition"
          });
      }


      if (
        !isLead
      ) {
        return res
          .status(403)
          .json({
            error:
              "Team Lead permission required"
          });
      }


      /*
        Same consistency rule as tasks:
        after investigation begins, the issue definition is locked.
        Team Lead may still change severity or owner.
      */

      if (
        incident.status ===
        "investigating"
      ) {
        const coreChangeRequested =
          (
            title !== undefined &&
            cleanText(
              title,
              200
            ) !== incident.title
          )
          ||
          (
            description !== undefined &&
            cleanText(
              description,
              5000
            ) !==
            (
              incident.description ||
              ""
            )
          )
          ||
          (
            category !== undefined &&
            cleanText(
              category,
              50
            ) !== incident.category
          );

        if (
          coreChangeRequested
        ) {
          return res
            .status(400)
            .json({
              error:
                "Title, description and category are locked after investigation has started. Reassign or change severity only."
            });
        }
      }


      const nextCategory =
        category === undefined
          ?
          incident.category
          :
          cleanText(
            category,
            50
          );

      if (
        !VALID_CATEGORIES.includes(
          nextCategory
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid incident category"
          });
      }

      const nextOwnerId =
        owner_user_id === undefined
          ?
          nullableId(
            incident.owner_user_id
          )
          :
          nullableId(
            owner_user_id
          );

      if (
        Number.isNaN(
          nextOwnerId
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "Invalid owner"
          });
      }

      let nextOwnerName =
        incident.owner_name ||
        null;

      if (
        nextOwnerId !== null
      ) {
        const member =
          await getEligibleMember(
            incident.project_id,
            nextOwnerId,
            nextCategory
          );

        if (
          !member
        ) {
          return res
            .status(400)
            .json({
              error:
                `${nextCategory} incidents can only be assigned to ${assignmentRule(nextCategory)}`
            });
        }

        nextOwnerName =
          member.name;
      }
      else {
        nextOwnerName =
          null;
      }

      const updates = [];
      const values = [];
      const changes = [];

      if (
        title !== undefined
      ) {
        const value =
          cleanText(
            title,
            200
          );

        if (
          !value
        ) {
          return res
            .status(400)
            .json({
              error:
                "Incident title cannot be empty"
            });
        }

        if (
          value !==
          incident.title
        ) {
          updates.push(
            "title=?"
          );

          values.push(
            value
          );

          changes.push(
            `title "${incident.title}" -> "${value}"`
          );
        }
      }

      if (
        description !== undefined
      ) {
        const value =
          cleanText(
            description,
            5000
          );

        if (
          value !==
          (
            incident.description ||
            ""
          )
        ) {
          updates.push(
            "description=?"
          );

          values.push(
            value ||
            null
          );

          changes.push(
            "description updated"
          );
        }
      }

      if (
        category !== undefined &&
        nextCategory !==
        incident.category
      ) {
        updates.push(
          "category=?"
        );

        values.push(
          nextCategory
        );

        changes.push(
          `category ${incident.category} -> ${nextCategory}`
        );
      }

      if (
        severity !== undefined
      ) {
        const value =
          cleanText(
            severity,
            20
          );

        if (
          !VALID_LEVELS.includes(
            value
          )
        ) {
          return res
            .status(400)
            .json({
              error:
                "Invalid incident severity"
            });
        }

        if (
          value !==
          incident.severity
        ) {
          updates.push(
            "severity=?"
          );

          values.push(
            value
          );

          changes.push(
            `severity ${incident.severity} -> ${value}`
          );
        }
      }

      const oldOwnerId =
        nullableId(
          incident.owner_user_id
        );

      if (
        owner_user_id !== undefined &&
        nextOwnerId !==
        oldOwnerId
      ) {
        updates.push(
          "owner_user_id=?"
        );

        values.push(
          nextOwnerId
        );

        changes.push(
          `owner ${incident.owner_name || "Unassigned"} -> ${nextOwnerName || "Unassigned"}`
        );

        if (
          incident.status ===
          "investigating"
        ) {
          updates.push(
            "status='new'"
          );

          updates.push(
            "resolution_note=NULL"
          );

          updates.push(
            "resolved_at=NULL"
          );

          changes.push(
            "status reset to new"
          );
        }
      }

      if (
        !updates.length
      ) {
        return res.json({
          message:
            "No incident changes"
        });
      }

      values.push(
        incidentId
      );

      await pool.query(
        `
        UPDATE incidents

        SET
          ${updates.join(", ")}

        WHERE id = ?
        `,
        values
      );

      await logActivity(
        incident.project_id,
        req.user.id,
        "incident",
        incidentId,
        `Incident "${incident.title}" updated: ${changes.join("; ")}`
      );

      res.json({
        message:
          "Incident updated"
      });
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to update incident"
        });
    }
  }
);


/* =====================================================
   ACTIVITY
===================================================== */

app.get(
  "/api/activity",
  requireAuth,
  async (
    req,
    res
  ) => {
    try {
      let sql =
        `
        SELECT
          a.id,
          a.entity_type,
          a.entity_id,
          a.action,
          a.created_at,

          p.name AS project_name,

          u.name AS user_name

        FROM activity_logs a

        LEFT JOIN projects p
          ON p.id = a.project_id

        LEFT JOIN users u
          ON u.id = a.user_id
        `;

      const params = [];

      if (
        req.user.role !==
        "Team Lead"
      ) {
        sql +=
          `
          WHERE EXISTS(
            SELECT 1

            FROM project_members pm

            WHERE
              pm.project_id = a.project_id
              AND pm.user_id = ?
          )
          `;

        params.push(
          req.user.id
        );
      }

      sql +=
        `
        ORDER BY
          a.created_at DESC

        LIMIT 100
        `;

      const [rows] =
        await pool.query(
          sql,
          params
        );

      res.json(rows);
    }
    catch (error) {
      console.error(error);

      res
        .status(500)
        .json({
          error:
            "Failed to load activity"
        });
    }
  }
);


/* =====================================================
   START
===================================================== */

app.listen(
  PORT,
  () => {
    console.log(
      `TeamOps API running on http://localhost:${PORT} [${APP_VERSION}]`
    );
  }
);