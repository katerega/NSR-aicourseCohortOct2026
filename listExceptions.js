const express = require("express");
const router = express.Router();
const db = require("../db");

router.get("/", async (req, res) => {
    try {
        const [rows] = await db.query(
            `SELECT r.*, i.invoice_number, i.vendor_name,
                    i.amount, i.currency
             FROM reconciliations r
             JOIN invoices i ON i.id = r.invoice_id
             WHERE r.status = 'EXCEPTION'
             ORDER BY r.created_at DESC`
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
