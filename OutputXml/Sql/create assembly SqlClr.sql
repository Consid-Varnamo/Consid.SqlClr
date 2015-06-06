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

if OBJECT_ID(N'XmlToFile', N'PC') is not null
	drop procedure XmlToFile

go

if exists(select * from sys.assemblies where name = 'Consid.SqlClr')
	drop assembly [Consid.SqlClr]

go

declare @debug bit = 0
declare @assemblyPath nvarchar(256)
declare @assemblySql nvarchar(512)

if @debug = 1
	set @assemblyPath = 'D:\users\chrhei\documents\visual studio 2013\Projects\SQLCLR\OutputXML\bin\Debug\Consid.SqlClr.dll'
else
	set @assemblyPath = 'D:\users\chrhei\documents\visual studio 2013\Projects\SQLCLR\OutputXML\bin\Release\Consid.SqlClr.dll'


set @assemblySql = 'create assembly [Consid.SqlClr] from ''' + @assemblyPath + ''' with permission_set = unsafe'
exec sp_executesql @assemblySql

go

create procedure XmlToFile(@data xml, @filename nvarchar(512)) 
as external name [Consid.SqlClr].[Consid.SqlClr.StoredProcedures].XmlToFile

go

alter authorization on database::dbBokrondellenCommerce_Upgrade to sa

go
