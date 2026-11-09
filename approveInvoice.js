const express = require("express");
const router = express.Router();
const db = require("../db");

router.post("/:id/approve", async (req, res) => {
    try {
        const { reviewed_by, notes } = req.body;

        const [result] = await db.query(
            `UPDATE approvals
             SET status = 'APPROVED',
                 reviewed_by = ?,
                 notes = ?,
                 reviewed_at = NOW()
             WHERE id = ? AND status = 'PENDING'`,
            [reviewed_by || null, notes || null, req.params.id]
        );

        if (!result.affectedRows) {
            return res.status(404).json({
                error: "Pending approval not found"
            });
        }

        await db.query(
            "UPDATE invoices SET status = 'APPROVED' WHERE id = (SELECT invoice_id FROM approvals WHERE id = ?)",
            [req.params.id]
        );

        res.json({
            success: true,
            message: "Invoice approved"
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
