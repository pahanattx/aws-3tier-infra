require("dotenv").config();

const bcrypt = require("bcryptjs");
const pool = require("./db");

async function main() {

    const leadPassword =
        process.env.DEMO_LEAD_PASSWORD;

    const memberPassword =
        process.env.DEMO_MEMBER_PASSWORD;


    if (!leadPassword || !memberPassword) {

        throw new Error(
            "DEMO_LEAD_PASSWORD and DEMO_MEMBER_PASSWORD must exist in .env"
        );
    }


    const leadHash =
        await bcrypt.hash(
            leadPassword,
            12
        );


    const memberHash =
        await bcrypt.hash(
            memberPassword,
            12
        );


    await pool.query(
        `
        UPDATE users
        SET password_hash = ?
        WHERE email = ?
        `,
        [
            leadHash,
            "sara@example.com"
        ]
    );


    await pool.query(
        `
        UPDATE users
        SET password_hash = ?
        WHERE email IN (
            'maya@example.com',
            'nimal@example.com',
            'kasun@example.com',
            'ravi@example.com',
            'dilan@example.com'
        )
        `,
        [
            memberHash
        ]
    );


    console.log(
        "All TeamOps demo accounts configured successfully."
    );


    await pool.end();
}


main().catch(
    async error => {

        console.error(
            error.message
        );

        try {
            await pool.end();
        }
        catch {
        }

        process.exit(1);
    }
);