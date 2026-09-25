# Backblaze CSV Data Loader

The purpose of these programs is to load the quarterly Backblaze SMART exports.

These files are probably the fourth or fifth generation where I would code a process and then as I progressed through the years of the Backblaze CSV
files, I would encounter insufferable slowdowns to the point where I'd identify what's causing the slowdown and figure a way to improve it - either
by tweaking it or rewriting it from scratch. A quarterly dataset loads in a few hours.

The application is written in CFML and will run in both Lucee and Adobe ColdFusion.

### Background
Originally, I used MySQL's bulk load ability on the CSV files to load into a master table but after partitioning the table to have SELECT statements
return data in a barely reasonable time frame, the bulk loads took much, much longer. I initially worked around it by identifying which drives were in
what partition and sorting the CSV file but I eventually dropped it for the current method.

I broke the process into three steps:<br>
Step 1: creating a separate CSV file for each model & date. Each CSV file name would have a Base36 derived from a Base 16 MD5 Hash of the file's
header, so files with a different header aren't loaded together.<br>
Step 2: Create SQL to insert all data for a given model & header<br>
Step 3: Execute the SQL to load the data. If the datasource is set to not allow multiple statements, they are executed one at a time. If multiple
statements are allowed, the SQL will be bulked together to the maximum allowed by the MySQL server and sent in one batch - much *much* faster than
one at a time.

### Why? Backblaze even has a query API
Well, I started this project before the API was available and I wanted to experiment with loading and processing massive amounts of data.

Basically, I wanted to. So there.

## Setup Notes
#### MySQL Server - [mysqld] section
Bulk loading will perform faster if you move the redo/undo logs to a different drive, preferably a fast NVMe. Also other following options help speed
up imports
```
innodb_log_group_home_dir = G:/MySQL_Undo
innodb_undo_tablespaces = 2  # or however many you use
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 40G   # or 70–80% of RAM
```

## Schema Layout
* backblaze
  * hgst_hds5c4040ale630
    * SerialID (int UN PK)
    * Date (date PK)
    * Failure (tinyint UN)
    * Age (smallint UN)
    * N_1 (tinyint UN) *normalized value*
    * R_2 (int UN) *raw value*
    * *additional smart id attributes repeated, sized to fit the data*
  * hgst_hds724040ale640
  * *Each model has it's own table with the schema being the model name with invalid characters replaced with underscore*
* backblaze2
  * models
    * ModelID (int UN AI PK)
    * Model (varchar) *Model name from CSV file*
    * SchemaName (varchar) *sanitized model name, used for the table in the backblaze schema*
    * Capacity (bigint UN) *Model capacity in bytes*
    * Ignore (big UN) *If this model contains all bad or undesired information, don't include in reports*
    * TotalDrives (int UN) *total unique serial numbers*
    * FailedDrives (int UN) *total number of drives with the failure flag set*
    * DriveDays (int UN) *Total number of days reported by all drives of that model*
    * PartitionCount (smallint UN) *Number of partitions the backblaze table has
    * Compressed (int UN) *If the backblaze table was analyzed to compress the data types to fit the data and all-NULL columns removed*
  * pendingload *holds the generated SQL files for loading*
    * LoadID (int UN AI PK)
    * SQLFile (varchar PK) *Full path and file name*
    * Processed (bit) *0/1 = true/false*
    * DateStamp (datetime) *Date the file was created*
    * ModelID (int UN) *This and SerialID is used for sorting purposes*
    * SerialID (int UN)
  * serial_numbers *Holds the information on each drive*
    * SerialID (int UN AI PK) *Used to reference the drive instead of the full serial number*
    * Dupe (bit) *Reserved for future logic to identify re-used serial numbers on new drives*
    * ModelID (int UN) *Reference Model table*
    * Serial_Number (varchar) *Full serial number*
    * First_Date (date) *Date first found*
    * Last_Date (date) *Last date of data, NULL if last day of data is also the last date of the dataset*
    * Failed (bit) *Indicates if the CSV had the Failure flag set*
    * PartitionID (tinyint UN) *Represents the partition the drive exists on, used for grouping of inserts*
  * smart *SMART ID reference table*
    * ID (smallint UN PK) *SMART ID value*
    * Name (varchar) *Description of the SMART ID attribute*

## Application.cfm
This program is executed by the app server prior to each program and sets up the environment.

> [!NOTE]
> The following files are numbered to aid in the processing order.

## 01_SetPartitionIDsOnSerials.cfm
Updates the PartitionID column in the backbalze2.serial_numbers table for any table in the backblaze schema that has been partitioned. Used to group
drives that exist on the same partition together. It can be skipped until `10_PartitionDBs.cfm` is executed.

## 02_DropIndexes_optional.cfm
If you like to rebuild your indexes after loading a lot of data or wanting to give a minor boost to importing the data, this will drop indexes on the
backblaze schema.

## 03_ParseCSVFiles.cfm
Referenced as `Step 1` above. This loops over the backblaze CSV files. During processing of each file, it:
1. Creates the model table in the `backblaze` schema if it doesn't exist. Initially, it will contain columns for all SMART ID's that backblaze has
ever reported in their CSV files.
2. Caches all previously created SerialIDs so it doesn't have to perform a database lookup to get the Serial ID for a given serial number.
3. Scans the file header to see if new SMART ID attributes are being passed in that do not exist in the SMART ID list in the `Application.cfm` file.
If found, it will alert to the issue and stop processing. You would then update the Application.cfm to add the ID.
4. Locates the location of the following columns in addition to the SMART ID attributes, all other columns are dropped in the new CSV file:<br>
date, serial_number, model, capacity_bytes, failure
5. Loads the entire CSV file into a variable and then converts that long text variable into an array with a delimiter of the Line Feed character after
stripping out Carriage Returns. Looping over an array of small strings is much faster than looping over a variable as a list when it contains a lot of data.
6. Create entries in the backblaze2 schema, model & serial_number if not existing in the cache for each row. This is visually reflected in the very first
file taking a long time to process followed by the 2nd file processing in only a fraction of the time. Large additions of new drives is represented in
slight stutters or pauses in the file processing percentage.
7. The model capacity is not always reflected the same by all drives of the same model. After at least 5 drives has been processed for a given model, the
capacity values are tallied and the one with the most of the same capacity is logged in the `backblaze2.serial_number` table.

## 04_CreateInsertSQL.cfm
Referenced as `Step 2` above. This creates INSERT SQL for the CSV files created in the previous step.

1. Scan the table for the SQL to check that it has the SMART ID columns referenced in the CSV file. IF there are new SMART ID attributes being sent by
Backblaze, they are added to the backblaze schema table.
2. Eliminate all null columns. Previous iterations of this load process would create a 2D array storing the entire file in, then check each column until
it hits a row with data. If it reaches the last row, that column is removed from each row. The next iteration started the check from the last row to the
first. This iteration creates a 2D array of the CSV file by converting the file into an array on the line delimiter and then each line into an array
by the comma delimiter. The 2D array is then converted into a in-memory query object in one function call to the QueryAddRow function. The last row of
the query is checked for NULL values, then a full SELECT is done on the table without the NULL only columns, resulting in a much smaller dataset.
This smaller dataset is then converted into a JSON variable and a series of Replace function calls are performed on it to change it into a SQL VALUES
block for the INSERT command.

If the resulting SQL and its insert VALUE array is too large for the MySQL max data packet, it will be broken up so as much as that can fit with a small
buffer is in each SQL chunk.
3. Adds the SQL file to the `pendingload` table.

Side ntoe: The INSERT command has the IGNORE option so if a SQL file is executed more than one time, it doesn't generate an error for duplicate PK
violations. It also doesn't load in *any* row that contains an error, such as an integer value that is too large for the SMART ID column from running
`06_DropNULLColumns.cfm` which drops any all-NULL columns and shrinks the datatype to fit the data, saving a lot of disk space. This truncation issue is
resolved in `99_Audit.cfm`.

## 05_LoadPendingFiles.cfm
Referenced as `Step 3` above. It will either submit the SQL files to the database one at a time based on the `pendingload` table if the datasource
doesn't allow multiple SQL statements in one query call or batches the SQL up until it's the maximum size allowed by the MySQL database.

If MySQL returns an error about a column not being found, this file will add the column.

## 06_DropNULLColumns.cfm
On initial creation of each model table, it is defined with all known SMART ID attributes that Backblaze has ever sent with each one being a BIGINT.
The program checks `backblaze2.models` to see what tables have been optimized (note: any time the other programs add a column, the optimized flag is
cleared) and performs the optimization on it. Model tables must also have at least 500 rows to be optimized.

A SELECT query is executed to get the max value for each SMART ID column which does involve a full table scan so the larger tables will take a bit to
execute. Each column's maximum value is compared to the datatype of the column. If the value can fit into a smaller unsigned integer datatype, it is
altered to update to that datatype. If a column's max value is a NULL (no data), then that column is dropped.

## 07_CreateIndexes.cfm
Scans through the model tables and adds any indexes needed to new model tables or ones that were dropped in 02_DropIndexes_optional.cfm

## 08_SetLastDate_Age.cfm
This will update the FirstDate and LastDate columns on `backblaze2.serial_numbers`. FirstDate will typically be set but if the audit process below
identifies and adds any missing data, it is cleared out. If the LastDate is the same as the last date in the tables, it is set to NULL as still being
in active status.

## 09_UpdateStatistics.cfm
Updates the `backblaze2.models` table to update the statistics for each model.

## 10_PartitionDBs.cfm
For model tables that have a lot of rows, SELECTING information on specific drives will start taking longer to finish. This program will partition the
model table on the SerialID column with the goal of having at most 1,000 drives in a given partition. It will typically end up being less than 1,000
due to the number of partitions being powers of 2, or increasing from 1 to 2, then 4, then 8, then 16, and so on with the maximum number of partitions
being 128.

## 99_Audit.cfm
This program counts the number of data lines in Backblaze CSV files and then selects all drives for that file's data from the model tables. If the count
matches, it moves onto the next CSV file. If the count does not match, it identified which models are missing data in the database and builds a SQL
query to insert them without the IGNORE command. Any errors returned from MySQL is displayed to the user to correct before re-running this program.

I had originally created this program as a sanity check for the other processes but when I got to 2025 after loading one year after another from the
start, I started to see missing data. The root cause of the missing rows ended up being values that eventually exceeded the integer datatype that was
set on previous years from running `06_DropNULLColumns.cfm`. I added a check for that error message and if found, the SQL to set that column back to
BIGINT was given to be manually ran. After seeing multiple columns being presented one after the other, I ended up manually updating every column
after to bigint and letting `06_DropNULLColumns.cfm` adjust back down after the data was loaded and counts matched.
