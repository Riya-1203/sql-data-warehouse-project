/*
--Create database and schemas--

Script Purpose: 
This script creates a new database called 'Datawarehouse' and defines 
three schemas within it: 'bronze', 'silver', and 'gold'. 
It first checks if the database already exists, and if so, it drops it 
before creating a new one.

Warning:
Running this script will delete the existing 'Datawarehouse' database and all its data. 
Ensure you have backups if necessary before executing this script.
*/

Use Master;
GO

--drop and recreate the 'Datawarehouse' database
If exists (select * from sys.databases where name = 'Datawarehouse')
BEGIN
    Alter Database Datawarehouse Set Single_User With Rollback Immediate;
    Drop Database Datawarehouse;
END;
GO

--Create the Datawarehouse database 
Create Database Datawarehouse;
GO

Use Datawarehouse;
GO

--Create schemas
Create Schema bronze;
GO

Create Schema silver;
GO

Create Schema gold;
GO
