const express = require("express");
const router = express.Router();
const multer = require("multer");
const axios = require("axios");
const FormData = require("form-data");
const fs = require("fs");

const upload = multer({
    dest: "uploads/",
    limits: { fileSize: 15 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        cb(null, file.mimetype === "application/pdf");
    }
});

router.post("/", upload.single("invoice"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "PDF invoice required" });
        }

        const form = new FormData();

        form.append("data", fs.createReadStream(req.file.path), {
            filename: req.file.originalname,
            contentType: "application/pdf"
        });

        const result = await axios.post(
            process.env.N8N_INVOICE_WEBHOOK,
            form,
            {
                headers: form.getHeaders(),
                timeout: 180000
            }
        );

        res.status(200).json({
            success: true,
            message: "Invoice processed",
            data: result.data
        });

    } catch (error) {
        res.status(500).json({
            error: error.response?.data || error.message
        });
    }
});

module.exports = router;
