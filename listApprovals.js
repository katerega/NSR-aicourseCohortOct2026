const express = require("express");
const router = express.Router();
const db = require("../db");

router.get("/", async (req, res) => {
    try {
        const [rows] = await db.query(
            `SELECT a.*, i.invoice_number, i.vendor_name,
                    i.amount, i.currency,
                    i.reconciliation_status
             FROM approvals a
             JOIN invoices i ON i.id = a.invoice_id
             WHERE a.status = 'PENDING'
             ORDER BY a.created_at DESC`
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
