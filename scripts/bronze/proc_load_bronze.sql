/* 
*********
Stored Procedure: Load Bronze Layer(Source-Bronze)
Script Purpose:
This stored procedure loads data into the 'bronze' schema from external CSV files.
It performs the following actions:
-Truncates the bronze tables before loading data.
-Uses the BULK INSERT command to load data from csv files to bronze tables.

Usage Example: (how to execute)
   EXEC bronze.load_bronze;
*********
*/
Create OR Alter Procedure bronze.load_bronze as 
BEGIN
    Declare @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        Print '********************';
        Print 'LOADING BRONZE LAYER';
        Print '********************';

        Print '------------------';
        Print 'LOADING CRM TABLES';
        Print '------------------';

        SET @start_time = GETDATE();
        Truncate Table bronze.crm_cust_info;
        Print '>>Inserting data into: bronze.crm_cust_info';
        Bulk Insert bronze.crm_cust_info
        From 'D:\sql\sqldocs3\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        With (
             Firstrow = 2,
             Fieldterminator = ',',
             Tablock
        );
        SET @end_time = GETDATE();
        Print '>>Time taken to load bronze.crm_cust_info: '+ CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';


        SET @start_time = GETDATE();
        Truncate Table bronze.crm_prd_info;
        Print '>>Inserting data into: bronze.crm_prd_info';
        Bulk Insert bronze.crm_prd_info
        From 'D:\sql\sqldocs3\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        With (
             Firstrow = 2,
             Fieldterminator = ',',
             Tablock
        );
        SET @end_time = GETDATE();
        Print '>>Time taken to load bronze.crm_prd_info: '+ CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';

        SET @start_time = GETDATE();
        Truncate Table bronze.crm_sales_details;
        Print '>>Inserting data into: bronze.crm_sales_details';
        Bulk Insert bronze.crm_sales_details
        From 'D:\sql\sqldocs3\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        With (
             Firstrow = 2,
             Fieldterminator = ',',
             Tablock
        );
        SET @end_time = GETDATE();
        Print '>>Time taken to load bronze.crm_sales_details: ' + CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';


        Print '------------------';
        Print 'LOADING ERP TABLES';
        Print '------------------';

        SET @start_time = GETDATE();
        Truncate Table bronze.erp_cust_az12;
        Print '>>Inserting data into: bronze.erp_cust_az12';
        Bulk Insert bronze.erp_cust_az12
        From 'D:\sql\sqldocs3\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
        With (
             Firstrow = 2,
             Fieldterminator = ',',
             Tablock
        );
        SET @end_time = GETDATE();
        Print '>>Time taken to load bronze.erp_cust_az12: ' +CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';

        SET @start_time = GETDATE();
        Truncate Table bronze.erp_loc_a101;
        Print '>>Inserting data into: bronze.erp_loc_a101';
        Bulk Insert bronze.erp_loc_a101
        From 'D:\sql\sqldocs3\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
        With (
             Firstrow = 2,
             Fieldterminator = ',',
             Tablock
        );
        SET @end_time = GETDATE();
        Print '>>Time taken to load bronze.erp_loc_a101: ' + CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';


        SET @start_time = GETDATE();
        Truncate Table bronze.erp_px_cat_g1v2;
        Print '>>Inserting data into: bronze.erp_px_cat_g1v2';
        Bulk Insert bronze.erp_px_cat_g1v2
        From 'D:\sql\sqldocs3\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
        With (
             Firstrow = 2,
             Fieldterminator = ',',
             Tablock
        );
        SET @end_time = GETDATE();
        Print '>>Time taken to load bronze.erp_px_cat_g1v2: ' + CAST(DATEDIFF(second, @start_time, @end_time) as NVARCHAR) + 'seconds';
        Print '-------------------';
        SET @batch_end_time = GETDATE();
        Print '********************';
        Print '>>Total time taken to load bronze layer: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) as NVARCHAR) + 'seconds';
        Print '********************';
    END TRY
    BEGIN CATCH
        Print '----ERROR OCCURED WHILE LOADING BRONZE LAYER-----';
        Print 'Error Message:' + ERROR_MESSAGE();
    END CATCH
END
