declare @output xml

exec dbo.ExportCatalogXml 'D102', @output output

exec dbo.OutputXml @output, 'd:\websites\Bokrondellen (clean install)\import\ImportUtility\Sql\Catalog.xml'


