use master

go

sp_configure 'show advanced options', 1

go

reconfigure

go

sp_configure 'clr enabled', 1

go

reconfigure

go

sp_configure 'show advanced options', 0

go

alter database dbBokrondellenCommerce_Upgrade
set trustworthy on

go

use dbBokrondellenCommerce_Upgrade

if OBJECT_ID(N'OutputXml', N'PC') is not null
	drop procedure OutputXml

go

if exists(select * from sys.assemblies where name = 'SqlClr')
	drop assembly SqlClr

go

create assembly SqlClr 
from 'D:\users\chrhei\documents\visual studio 2013\Projects\SQLCLR\OutputXML\bin\Release\SqlClr.dll'
with permission_set = unsafe

go

create procedure OutputXml(@data xml, @filename nvarchar(512)) 
as external name [SqlClr].[SqlClr.StoredProcedures].OutputXml

go

alter authorization on database::dbBokrondellenCommerce_Upgrade to sa

go

-- select name, suser_sname(owner_sid) from sys.databases where name = 'dbBokrondellenCommerce_Upgrade'
