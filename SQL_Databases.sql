/* Вывести название, путь и размер всех файлов на локальном SQL Server (ROWS / LOG), 
которые не относятся к системным базам данных.*/

SELECT *
FROM sys.databases
WHERE [name] NOT IN ('master', 'tempdb', 'model', 'msdb')

/*Вывести название всех баз на сервере с размером в MB.*/

--For all Databases in Mb
EXEC sp_helpdb

--For curent Database in Mb
SELECT SUM (CAST(size / 128.0 AS DECIMAL(17,2))) AS [Size in Mb for curent Database]
FROM sys.database_files

/*Вывести название всех таблиц, количество колонок и 
размер для всех несистемных баз данных (DbName, TableName, ColumnsCount, TableSize).*/

SELECT*
INTO [AdventureWorksDW2019].[dbo].[AllInformation]
FROM
  AdventureWorks2019.INFORMATION_SCHEMA.TABLES
UNION ALL
SELECT*
FROM
  AdventureWorksDW2019.INFORMATION_SCHEMA.TABLES
UNION ALL
SELECT*
FROM
  AdventureWorksLT2019.INFORMATION_SCHEMA.TABLES

/*Создать новую базу данных с названием NewDatabase. 
Создать в базе NewDatabase дополнительную файловую группу с название STAGING. 
Создать новый файл STAGING_DATA в файловой группе STAGING.*/

CREATE DATABASE [NewDatabase]
ON
  (NAME = 'STAGING_DATA',
  FILENAME = 'D:\SQL\STAGING_DATA')
LOG ON
  (NAME = 'STAGING',
  FILENAME = 'D:\SQL\STAGING')
  
/*Сделать бэкап базы AdventureWorksDW2019 со сжатием и без сжатия.*/

BACKUP DATABASE [AdventureWorksDW2019] TO DISK='D:\SQL\AdventureWorksDW2019_Full.bak'
/*BACKUP DATABASE successfully processed 315362 pages in 4.854 seconds (507.573 MB/sec).
Size: 2,524,356 KB*/

BACKUP DATABASE [AdventureWorksDW2019] TO DISK='D:\SQL\AdventureWorksDW2019_Compressed.bak'
WITH COMPRESSION
/*BACKUP DATABASE successfully processed 315362 pages in 2.982 seconds (826.211 MB/sec).
Size: 108,160 KB*/

/*Восстановите базу с названием RestoreTest из бэкапа базы AdventureWorksDW2019.*/

RESTORE DATABASE [AdventureWorksDW2019]  
FROM DISK = 'D:\SQL\AdventureWorksDW2019_Compressed.bak'