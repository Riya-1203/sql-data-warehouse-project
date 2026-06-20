/*
***********************
Stored Procedure: Load Silver Layer(Bronze-> Silver)
***********************
Script Purpose:
  This stored produre performs the ETL (Extract, transform, load) process to populate
  the 'Silver' schema tables from the 'Bronze' schema.
 Actions Performed:
  - truncates silver tables.
  - inserts transformed and cleaned data from Bronze into Siler tables.

Usage Example:
  EXEC Silver.load_silver
***********************
*/

Create OR Alter Procedure silver.load_silver as 
BEGIN
    Declare @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        Print '********************';
        Print 'LOADING SILVER LAYER';
        Print '********************';

        Print '------------------';
        Print 'LOADING CRM TABLES';
        Print '------------------';

        SET @start_time = GETDATE();
        Truncate Table silver.crm_cust_info;
        Print '>>Inserting data into: silver.crm_cust_info';
        --check for duplicates and nulls  in cst_id(primary key)
        --trim the string columns

        Insert into silver.crm_cust_info(
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
        )
        select 
        cst_id,
        cst_key,
        trim(cst_firstname) as cst_firstname,
        trim(cst_lastname) as cst_lastname,
        case when upper(trim(cst_marital_status)) = 'M' then 'Married'
             when upper(trim(cst_marital_status)) = 'S' then 'Single'
	         else 'n/a'
        end as cst_marital_status, -- normalize marital status into easily readable format
        case when upper(trim(cst_gndr)) = 'M' then 'Male'
             when upper(trim(cst_gndr)) = 'F' then 'Female'
	         else 'n/a' 
        end as cst_gndr,  -- normalize gender into easily readable format
        cst_create_date
        from (
	        select
	        *,
	        row_number() over (partition by cst_id order by cst_create_date desc) as row_num
	        from bronze.crm_cust_info
	        where cst_id is not null 
        )t
        where row_num = 1; --select most recent record per customer based on create date
        SET @end_time = GETDATE();
        Print '>>Time taken to load silver.crm_cust_info: '+ CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';


        SET @start_time = GETDATE();
        Truncate Table silver.crm_prd_info;
        Print '>>Inserting data into: silver.crm_prd_info';
        Insert into silver.crm_prd_info(
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
        )
        select
        prd_id, 
        REPLACE(substring(prd_key,1,5),'-', '_') as cat_id, -- extract category id from product key to use for joining with product category table
        SUBSTRING(prd_key, 7, len(prd_key)) as prd_key, -- extract product key without category id for easier joining with sales details table
        prd_nm,
        isnull(prd_cost, 0) as prd_cost,
        Case UPPER(trim(prd_line))
             when  'R' then 'Road'
	         when  'M' then 'Mountain'
	         when  'S' then 'Other Sales'
	         when  'T' then 'Touring'
	         else  'n/a'
        END as prd_line,  -- normalize product line into easily readable format
        cast(prd_start_dt as date) as prd_start_dt,  -- convert to date data type for easier handling
        cast(LEAD(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as date) as prd_end_dt
        from bronze.crm_prd_info 
        SET @end_time = GETDATE();
        Print '>>Time taken to load silver.crm_prd_info: '+ CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';

        SET @start_time = GETDATE();
        Truncate Table silver.crm_sales_details;
        Print '>>Inserting data into: silver.crm_sales_details';
        Insert into silver.crm_sales_details(
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
        )
        select
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        Case when sls_order_dt = 0 or LEN(sls_order_dt) !=8 then null
             else Cast(CAST(sls_order_dt as varchar) as date)  --we cannot convert int into date directly
        END as sls_order_dt,
        Case when sls_ship_dt = 0 or LEN(sls_ship_dt) !=8 then null
             else Cast(CAST(sls_ship_dt as varchar) as date)  
        END as sls_ship_dt,
        Case when sls_due_dt = 0 or LEN(sls_due_dt) !=8 then null
             else Cast(CAST(sls_due_dt as varchar) as date)  
        END as sls_due_dt,
        Case when sls_sales is null or sls_sales<=0 or sls_sales != sls_quantity* ABS(sls_price)
                  then sls_quantity * ABS(sls_price)
             else sls_sales
        END as sls_sales,
        sls_quantity, 
        Case when sls_price is null or sls_price <=0
                  then sls_sales / NULLIF(sls_quantity,0)
             else sls_price
        END as sls_price
        from bronze.crm_sales_details
        SET @end_time = GETDATE();
        Print '>>Time taken to load silver.crm_sales_details: '+ CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';


        Print '------------------';
        Print 'LOADING ERP TABLES';
        Print '------------------';

        SET @start_time = GETDATE();
        Truncate Table silver.erp_cust_az12;
        Print '>>Inserting data into: silver.erp_cust_az12';
        Insert into silver.erp_cust_az12(
        cid,
        bdate,
        gen
        )
        select 
        Case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))  --extract cid to connect it with other table(remove 'NAS' prefix if present
             else cid
        END cid,
        Case when bdate > GETDATE() then Null
             else bdate
        END as bdate,  --Set future birthdates to NULL
        Case when UPPER(trim(gen)) in ('F', 'FEMALE') then 'Female'
             when UPPER(trim(gen)) in ('M', 'MALE') then 'Male'
             else 'n/a'  
        END as gen   --Normalize gender values and handle unknown cases
        from bronze.erp_cust_az12
        SET @end_time = GETDATE();
        Print '>>Time taken to load silver.erp_cust_az12: '+ CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';


        SET @start_time = GETDATE();
        Truncate Table silver.erp_loc_a101;
        Print '>>Inserting data into: silver.erp_loc_a101';
        Insert into silver.erp_loc_a101(
        cid,
        cntry
        )
        select
        REPLACE(cid, '-', ''),
        Case when TRIM(cntry) = 'DE' then 'Germany'
             when TRIM(cntry) in ('US', 'USA') then 'United States'
             when TRIM(cntry) = '' or cntry is null then 'n/a'
             else TRIM(cntry)
        END as cntry
        from bronze.erp_loc_a101
        SET @end_time = GETDATE();
        Print '>>Time taken to load silver.erp_loc_a101: '+ CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';

        SET @start_time = GETDATE();
        Truncate Table silver.erp_px_cat_g1v2;
        Print '>>Inserting data into: silver.erp_px_cat_g1v2';
        Insert into silver.erp_px_cat_g1v2(
        id,
        cat,
        subcat,
        maintenance
        )
        select 
        id,
        cat,
        subcat,
        maintenance
        from bronze.erp_px_cat_g1v2
        SET @end_time = GETDATE();
        Print '>>Time taken to load silver.erp_px_cat_g1v2: '+ CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';
        SET @batch_end_time = GETDATE();
        Print '********************';
        Print '>>Total time taken to load silver layer: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) as NVARCHAR) + 'seconds';
        Print '********************';
    END TRY
    BEGIN CATCH
        Print '----ERROR OCCURED WHILE LOADING SILVER LAYER-----';
        Print 'Error Message:' + ERROR_MESSAGE();
    END CATCH
END



