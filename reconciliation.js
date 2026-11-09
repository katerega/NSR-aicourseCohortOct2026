const express = require("express");
const router = express.Router();
const db = require("../db");

router.post("/", async (req, res) => {
    try {
        const { invoice_id } = req.body;

        const [invoices] = await db.query(
            "SELECT * FROM invoices WHERE id = ?",
            [invoice_id]
        );

        if (!invoices.length) {
            return res.status(404).json({ error: "Invoice not found" });
        }

        const invoice = invoices[0];

        if (!invoice.po_number) {
            return res.json({
                status: "EXCEPTION",
                discrepancy: "MISSING_PURCHASE_ORDER"
            });
        }

        const [pos] = await db.query(
            "SELECT * FROM purchase_orders WHERE po_number = ?",
            [invoice.po_number]
        );

        if (!pos.length) {
            return res.json({
                status: "EXCEPTION",
                discrepancy: "PURCHASE_ORDER_NOT_FOUND"
            });
        }

        const po = pos[0];
        const discrepancies = [];

        if (invoice.vendor_name !== po.vendor_name)
            discrepancies.push("VENDOR_MISMATCH");

        if (Math.abs(Number(invoice.amount) - Number(po.total_amount)) > 0.01)
            discrepancies.push("TOTAL_MISMATCH");

        const status = discrepancies.length ? "EXCEPTION" : "MATCHED";

        await db.query(
            `INSERT INTO reconciliations
             (invoice_id, status, discrepancies)
             VALUES (?, ?, ?)`,
            [invoice_id, status, JSON.stringify(discrepancies)]
        );

        await db.query(
            "UPDATE invoices SET reconciliation_status = ? WHERE id = ?",
            [status, invoice_id]
        );

        res.json({
            success: true,
            invoice_id,
            status,
            discrepancies,
            approval_required: true
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
