
-- ==========================================================
-- INVOICE IQ
-- AI INVOICE PROCESSING AND PO RECONCILIATION
-- MySQL 8.0+
-- ==========================================================

CREATE DATABASE IF NOT EXISTS invoice_iq
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE invoice_iq;

-- ==========================================================
-- 1. INVOICES
-- ==========================================================

CREATE TABLE IF NOT EXISTS invoices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    invoice_number VARCHAR(100) NOT NULL,
    vendor_name VARCHAR(255) NOT NULL,
    vendor_tax_id VARCHAR(100),

    invoice_date DATE,
    due_date DATE,

    po_number VARCHAR(100),

    subtotal DECIMAL(18,2) DEFAULT 0.00,
    tax_amount DECIMAL(18,2) DEFAULT 0.00,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(10) NOT NULL DEFAULT 'UGX',

    status ENUM(
        'UPLOADED',
        'PROCESSING',
        'PROCESSED',
        'PENDING_RECONCILIATION',
        'MATCHED',
        'EXCEPTION',
        'PENDING_APPROVAL',
        'APPROVED',
        'REJECTED',
        'FAILED'
    ) NOT NULL DEFAULT 'UPLOADED',

    original_filename VARCHAR(255),
    stored_file_path VARCHAR(1000),
    mime_type VARCHAR(100),

    extracted_data JSON,
    extraction_confidence DECIMAL(5,2),

    notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_invoice_vendor_number (vendor_name, invoice_number),
    INDEX idx_invoice_status (status),
    INDEX idx_invoice_date (invoice_date),
    INDEX idx_invoice_po (po_number),
    INDEX idx_invoice_vendor (vendor_name),
    INDEX idx_invoice_created (created_at)
) ENGINE=InnoDB;


-- ==========================================================
-- 2. INVOICE LINE ITEMS
-- ==========================================================

CREATE TABLE IF NOT EXISTS invoice_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    invoice_id BIGINT UNSIGNED NOT NULL,

    description VARCHAR(1000) NOT NULL,
    item_code VARCHAR(100),

    quantity DECIMAL(18,4) NOT NULL DEFAULT 1,
    unit_price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    line_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_invoice_items_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoices(id)
        ON DELETE CASCADE,

    INDEX idx_invoice_items_invoice (invoice_id)
) ENGINE=InnoDB;


-- ==========================================================
-- 3. PURCHASE ORDERS
-- ==========================================================

CREATE TABLE IF NOT EXISTS purchase_orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    po_number VARCHAR(100) NOT NULL UNIQUE,

    vendor_name VARCHAR(255) NOT NULL,
    vendor_tax_id VARCHAR(100),

    order_date DATE,
    expected_delivery_date DATE,

    subtotal DECIMAL(18,2) DEFAULT 0.00,
    tax_amount DECIMAL(18,2) DEFAULT 0.00,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,

    currency VARCHAR(10) NOT NULL DEFAULT 'UGX',

    status ENUM(
        'DRAFT',
        'OPEN',
        'PARTIALLY_RECEIVED',
        'RECEIVED',
        'CLOSED',
        'CANCELLED'
    ) NOT NULL DEFAULT 'OPEN',

    notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_po_vendor (vendor_name),
    INDEX idx_po_status (status),
    INDEX idx_po_date (order_date)
) ENGINE=InnoDB;


-- ==========================================================
-- 4. PURCHASE ORDER LINE ITEMS
-- ==========================================================

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    purchase_order_id BIGINT UNSIGNED NOT NULL,

    description VARCHAR(1000) NOT NULL,
    item_code VARCHAR(100),

    quantity DECIMAL(18,4) NOT NULL DEFAULT 1,
    unit_price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    line_total DECIMAL(18,2) NOT NULL DEFAULT 0.00,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_po_items_purchase_order
        FOREIGN KEY (purchase_order_id)
        REFERENCES purchase_orders(id)
        ON DELETE CASCADE,

    INDEX idx_po_items_order (purchase_order_id)
) ENGINE=InnoDB;


-- ==========================================================
-- 5. RECONCILIATIONS
-- ==========================================================

CREATE TABLE IF NOT EXISTS reconciliations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    invoice_id BIGINT UNSIGNED NOT NULL,
    purchase_order_id BIGINT UNSIGNED NULL,

    status ENUM(
        'MATCHED',
        'EXCEPTION',
        'PENDING',
        'FAILED'
    ) NOT NULL DEFAULT 'PENDING',

    vendor_match BOOLEAN DEFAULT FALSE,
    amount_match BOOLEAN DEFAULT FALSE,
    currency_match BOOLEAN DEFAULT FALSE,
    line_items_match BOOLEAN DEFAULT FALSE,

    invoice_total DECIMAL(18,2),
    po_total DECIMAL(18,2),
    difference_amount DECIMAL(18,2),

    exception_reason TEXT,
    reconciliation_details JSON,

    reconciled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reconciliation_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoices(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_reconciliation_po
        FOREIGN KEY (purchase_order_id)
        REFERENCES purchase_orders(id)
        ON DELETE SET NULL,

    INDEX idx_reconciliation_status (status),
    INDEX idx_reconciliation_invoice (invoice_id),
    INDEX idx_reconciliation_po (purchase_order_id),
    INDEX idx_reconciliation_date (reconciled_at)
) ENGINE=InnoDB;


-- ==========================================================
-- 6. RECONCILIATION LINE ITEM COMPARISONS
-- ==========================================================

CREATE TABLE IF NOT EXISTS reconciliation_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    reconciliation_id BIGINT UNSIGNED NOT NULL,

    invoice_item_id BIGINT UNSIGNED NULL,
    purchase_order_item_id BIGINT UNSIGNED NULL,

    invoice_description VARCHAR(1000),
    po_description VARCHAR(1000),

    invoice_quantity DECIMAL(18,4),
    po_quantity DECIMAL(18,4),

    invoice_unit_price DECIMAL(18,2),
    po_unit_price DECIMAL(18,2),

    invoice_line_total DECIMAL(18,2),
    po_line_total DECIMAL(18,2),

    matched BOOLEAN DEFAULT FALSE,
    difference_reason TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_recon_items_reconciliation
        FOREIGN KEY (reconciliation_id)
        REFERENCES reconciliations(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_recon_items_invoice_item
        FOREIGN KEY (invoice_item_id)
        REFERENCES invoice_items(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_recon_items_po_item
        FOREIGN KEY (purchase_order_item_id)
        REFERENCES purchase_order_items(id)
        ON DELETE SET NULL,

    INDEX idx_recon_items_reconciliation (reconciliation_id)
) ENGINE=InnoDB;


-- ==========================================================
-- 7. APPROVALS
-- ==========================================================

CREATE TABLE IF NOT EXISTS approvals (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    invoice_id BIGINT UNSIGNED NOT NULL,

    status ENUM(
        'PENDING',
        'APPROVED',
        'REJECTED'
    ) NOT NULL DEFAULT 'PENDING',

    requested_by VARCHAR(255),
    approved_by VARCHAR(255),
    rejected_by VARCHAR(255),

    approval_notes TEXT,
    rejection_reason TEXT,

    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME NULL,
    rejected_at DATETIME NULL,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_approval_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoices(id)
        ON DELETE CASCADE,

    UNIQUE KEY uq_approval_invoice (invoice_id),
    INDEX idx_approval_status (status),
    INDEX idx_approval_requested (requested_at)
) ENGINE=InnoDB;


-- ==========================================================
-- 8. AUDIT LOG
-- ==========================================================

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    entity_type VARCHAR(100) NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,

    action VARCHAR(100) NOT NULL,
    performed_by VARCHAR(255),

    old_values JSON,
    new_values JSON,

    ip_address VARCHAR(45),
    user_agent VARCHAR(500),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_audit_entity (entity_type, entity_id),
    INDEX idx_audit_action (action),
    INDEX idx_audit_date (created_at)
) ENGINE=InnoDB;


-- ==========================================================
-- 9. SYSTEM SETTINGS
-- ==========================================================

CREATE TABLE IF NOT EXISTS system_settings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    setting_key VARCHAR(150) NOT NULL UNIQUE,
    setting_value TEXT,

    description VARCHAR(500),

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- ==========================================================
-- 10. INITIAL SYSTEM SETTINGS
-- ==========================================================

INSERT INTO system_settings
    (setting_key, setting_value, description)
VALUES
    ('default_currency', 'UGX', 'Default invoice currency'),
    ('reconciliation_tolerance', '0.01', 'Allowed amount difference'),
    ('require_human_approval', '1', 'Require human approval before final approval'),
    ('invoice_upload_max_mb', '20', 'Maximum invoice PDF upload size')
ON DUPLICATE KEY UPDATE
    setting_value = VALUES(setting_value);


-- ==========================================================
-- DATABASE CREATION COMPLETE
-- ==========================================================

SELECT 'Invoice IQ database created successfully' AS result;
