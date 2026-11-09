const express = require("express");
const router = express.Router();
const db = require("../db");

router.get("/", async (req, res) => {
    try {
        const [rows] = await db.query(
            `SELECT * FROM purchase_orders
             ORDER BY created_at DESC`
        );

        res.json({
            success: true,
            data: rows
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
