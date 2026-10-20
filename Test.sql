-- =====================================================================================================
-- gold.vw_sales_details - every wholesaler's sales lines, described with the product master's PIP code,
-- SKU and product name. View requirement 1, "Sales details" (docs/view_requirements1.jpeg).
--
-- Rows      : one per sales line published in Gold.
--               AAH       gold.fact_daily_sales     Bayer Daily Sales
--               Williams  gold.fact_williams_sales  the weekly file and the sales history build-up: one
--                                                   feed in two layouts, landed in one table. Where both
--                                                   cover an invoice date, Silver keeps only the weekly
--                                                   file's lines, so a date is never counted twice.
-- Product   : pip_code, bayer_sku and bayer_product_name always come from the Wholesale Product Master
--             (gold.dim_product), never from the wholesaler's file. Silver has already matched every line
--             the way the requirement asks: AAH on the PIP code (rule PIP_EXACT, with the AAH product code
--             as a fallback), Williams on the Williams Product Name (rule WILLIAMS_NAME_EXACT, ignoring
--             case and spacing only). Note that the Williams material code rule, still pending on OD-06,
--             would match ahead of the name once activated - that departs from the requirement, so agree
--             it with the business first. The view follows the fact's product_key, so a line shows the
--             master version that was valid on its sale date. A line that matched no master product keeps
--             its volume and shows NULL in these three columns. For today's master values on every line,
--             look the product up by product_business_key with is_current = true instead.
-- Customer  : each wholesaler's own customer columns, lined up where they mean the same thing (the same
--             pairing silver.account_reference uses) and NULL where a wholesaler does not send one.
--             The AAH customer details and pack size come from the line's Silver row: the AAH fact keeps
--             the line's keys and measures, not its text.
-- Left out  : as requested - AAH Invoice Number and Sales Value; Williams Country Code and Material Code;
--             each wholesaler's own PIP code and product description, which the master values replace.
-- Not yet   : Phoenix (sales history build-up 2, tab SalesByChannel) and the AAH history build-up have no
--             feed in the platform, so there is nothing to read for them yet. Phoenix becomes a third
--             UNION ALL branch once it is loaded (see the note under the statement). If the AAH history
--             build-up has the Daily Sales layout, it can be delivered through the daily_sales feed (named
--             to match that feed's file_glob) and lands in gold.fact_daily_sales, with no change here.
-- Names     : physical names for the dev config in conf/platform.yaml, built as
--             <catalog>.<schema>.<layer prefix><table>. For another environment, change
--             efdataonelh_dev.default and the prefixes to match its platform.yaml.
-- Order     : gold.vw_sales_aggregated reads this view, so create this one first.
-- To confirm: the column names, against row 1 ("column name in view") of the business mapping sheet, and
--             the customer column pairing, against the same sheet. Neither sheet is in docs/ yet.
-- =====================================================================================================

CREATE OR REPLACE VIEW efdataonelh_dev.default.gold_vw_sales_details (
    wholesaler_name     COMMENT 'Wholesaler that reported the sale: AAH or Williams',
    sale_date           COMMENT 'AAH: Date. Williams: invoice date (history build-up: Despatch Date)',
    pip_code            COMMENT 'PIP Code from the Wholesale Product Master. NULL when the line matched no master product',
    bayer_sku           COMMENT 'SKU from the Wholesale Product Master. NULL when the line matched no master product',
    bayer_product_name  COMMENT 'Product Name from the Wholesale Product Master. NULL when the line matched no master product',
    volume              COMMENT 'Units sold, negative for a return. AAH: Volume. Williams: sales qty (history build-up: Sales (Units))',
    customer_code       COMMENT 'AAH: Account Number. Williams: Customer Code (history build-up: WMS Code)',
    customer_name       COMMENT 'AAH: Account Name. Williams: Customer Name (history build-up: Account Name)',
    customer_type       COMMENT 'AAH: Customer Type. NULL for Williams',
    customer_channel    COMMENT 'AAH: Customer Channel. NULL for Williams',
    customer_class      COMMENT 'Williams: Customer Class (history build-up: WMS Class). NULL for AAH',
    address_line_1      COMMENT 'AAH: Address Line 1. Williams history build-up: Delivery Address. NULL for the Williams weekly file',
    address_line_2      COMMENT 'AAH: Address Line 2. NULL for Williams',
    address_line_3      COMMENT 'AAH: Address Line 3. NULL for Williams',
    address_line_4      COMMENT 'AAH: Address Line 4. NULL for Williams',
    city                COMMENT 'Williams weekly file: Customer City. NULL for AAH and the Williams history build-up',
    post_code           COMMENT 'AAH: Post Code. Williams: Sales Order Delivery Post Code (history build-up: Address6)',
    print_branch        COMMENT 'AAH: Print Branch. NULL for Williams',
    account_branch      COMMENT 'AAH: Account Branch. NULL for Williams',
    aah_product_code    COMMENT 'AAH: AAH Product Code. NULL for Williams',
    ean_code            COMMENT 'AAH: EAN Code. NULL for Williams',
    pack_size           COMMENT 'AAH: Pack Size. NULL for Williams',
    dq_status           COMMENT 'PASS, or WARNING when a data quality rule flagged the line (the rule ids are on its Silver row)',
    source_file_name    COMMENT 'File the line was delivered in',
    source_fact_key     COMMENT 'Key of the line in its Gold fact: daily_sales_key (AAH) or williams_sales_key (Williams)')
COMMENT 'Sales lines from every wholesaler (AAH, Williams) with the PIP code, SKU and product name from the Wholesale Product Master. View requirement 1.'
AS
-- AAH: Bayer Daily Sales
SELECT
    'AAH'                               AS wholesaler_name,
    f.business_date                     AS sale_date,
    p.pip_code                          AS pip_code,
    p.sku                               AS bayer_sku,
    p.product_name                      AS bayer_product_name,
    f.volume                            AS volume,
    f.account_number                    AS customer_code,
    s.account_name                      AS customer_name,
    s.customer_type                     AS customer_type,
    s.customer_channel                  AS customer_channel,
    CAST(NULL AS STRING)                AS customer_class,
    s.address_line_1                    AS address_line_1,
    s.address_line_2                    AS address_line_2,
    s.address_line_3                    AS address_line_3,
    s.address_line_4                    AS address_line_4,
    CAST(NULL AS STRING)                AS city,
    s.post_code                         AS post_code,
    f.print_branch                      AS print_branch,
    f.account_branch                    AS account_branch,
    f.aah_product_code                  AS aah_product_code,
    f.ean_code                          AS ean_code,
    s.pack_size                         AS pack_size,
    f.dq_status                         AS dq_status,
    f.source_file_name                  AS source_file_name,
    f.daily_sales_key                   AS source_fact_key
FROM efdataonelh_dev.default.gold_fact_daily_sales AS f
LEFT JOIN efdataonelh_dev.default.silver_daily_sales AS s
       ON s.daily_sales_id = f.daily_sales_key
LEFT JOIN efdataonelh_dev.default.gold_dim_product AS p
       ON p.product_key = f.product_key

UNION ALL

-- Williams: weekly file and history build-up, both already under the weekly file's column names
SELECT
    'Williams'                          AS wholesaler_name,
    f.invoice_date                      AS sale_date,
    p.pip_code                          AS pip_code,
    p.sku                               AS bayer_sku,
    p.product_name                      AS bayer_product_name,
    f.sales_qty                         AS volume,
    f.customer_code                     AS customer_code,
    f.customer_name                     AS customer_name,
    CAST(NULL AS STRING)                AS customer_type,
    CAST(NULL AS STRING)                AS customer_channel,
    f.customer_class                    AS customer_class,
    f.delivery_address                  AS address_line_1,
    CAST(NULL AS STRING)                AS address_line_2,
    CAST(NULL AS STRING)                AS address_line_3,
    CAST(NULL AS STRING)                AS address_line_4,
    f.customer_city                     AS city,
    f.sales_order_delivery_post_code    AS post_code,
    CAST(NULL AS STRING)                AS print_branch,
    CAST(NULL AS STRING)                AS account_branch,
    CAST(NULL AS STRING)                AS aah_product_code,
    CAST(NULL AS STRING)                AS ean_code,
    CAST(NULL AS STRING)                AS pack_size,
    f.dq_status                         AS dq_status,
    f.source_file_name                  AS source_file_name,
    f.williams_sales_key                AS source_fact_key
FROM efdataonelh_dev.default.gold_fact_williams_sales AS f
LEFT JOIN efdataonelh_dev.default.gold_dim_product AS p
       ON p.product_key = f.product_key;

-- Adding Phoenix: once its feed is loaded into a Gold fact, add a third UNION ALL branch with
-- 'Phoenix' AS wholesaler_name. Keep the column order above, take the product from gold.dim_product
-- through the fact's product_key (Phoenix lines are to match on the PIP code, as AAH lines do), leave
-- out Sales Value, read only the SalesByChannel tab, and put NULL in every column Phoenix does not send.
-- Then add Phoenix to the wholesaler_name comment.

-- Check after creating (each wholesaler's line count and volume equal its fact's):
-- SELECT wholesaler_name, count(*) AS lines, sum(volume) AS volume,
--        count_if(pip_code IS NULL) AS lines_without_master_product
-- FROM efdataonelh_dev.default.gold_vw_sales_details
-- GROUP BY wholesaler_name;
-- SELECT count(*), sum(volume)    FROM efdataonelh_dev.default.gold_fact_daily_sales;
-- SELECT count(*), sum(sales_qty) FROM efdataonelh_dev.default.gold_fact_williams_sales;
