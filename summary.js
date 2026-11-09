const express = require("express");
const router = express.Router();
const db = require("../db");

router.get("/", async (req, res) => {
    try {
        const [[invoices]] = await db.query(
            `SELECT COUNT(*) AS total,
                    COALESCE(SUM(amount), 0) AS total_value
             FROM invoices`
        );

        const [[matched]] = await db.query(
            "SELECT COUNT(*) AS total FROM invoices WHERE reconciliation_status = 'MATCHED'"
        );

        const [[exceptions]] = await db.query(
            `SELECT COUNT(*) AS total FROM (
                SELECT invoice_id FROM reconciliations r
                WHERE r.id = (
                    SELECT MAX(r2.id) FROM reconciliations r2
                    WHERE r2.invoice_id = r.invoice_id
                )
                AND r.status = 'EXCEPTION'
            ) x`
        );

        const [[pending]] = await db.query(
            "SELECT COUNT(*) AS total FROM approvals WHERE status = 'PENDING'"
        );

        const [[approved]] = await db.query(
            "SELECT COUNT(*) AS total FROM approvals WHERE status = 'APPROVED'"
        );

        res.json({
            success: true,
            data: {
                total_invoices: invoices.total,
                total_value: invoices.total_value,
                matched: matched.total,
                exceptions: exceptions.total,
                pending_approvals: pending.total,
                approved: approved.total
            }
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
