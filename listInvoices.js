const express = require("express");
const router = express.Router();
const db = require("../db");

router.get("/", async (req, res) => {
    try {
        const page = Math.max(1, Number(req.query.page) || 1);
        const limit = Math.min(100, Number(req.query.limit) || 20);
        const offset = (page - 1) * limit;

        const [rows] = await db.query(
            `SELECT * FROM invoices
             ORDER BY created_at DESC
             LIMIT ? OFFSET ?`,
            [limit, offset]
        );

        const [[count]] = await db.query(
            "SELECT COUNT(*) AS total FROM invoices"
        );

        res.json({
            success: true,
            data: rows,
            total: count.total,
            page,
            limit
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;


