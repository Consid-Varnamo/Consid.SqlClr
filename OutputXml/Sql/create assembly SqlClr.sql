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

create assembly SqlClr 
from 'D:\users\chrhei\documents\visual studio 2013\Projects\SQLCLR\OutputXML\bin\Release\SqlClr.dll'
with permission_set = external_access

go

