const express = require("express");
const router = express.Router();
const db = require("../db");

router.get("/:id", async (req, res) => {
    try {
        const [rows] = await db.query(
            "SELECT * FROM invoices WHERE id = ?",
            [req.params.id]
        );

        if (!rows.length) {
            return res.status(404).json({ error: "Invoice not found" });
        }

        res.json({
            success: true,
            data: rows[0]
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
