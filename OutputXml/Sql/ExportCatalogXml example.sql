declare @output xml

exec dbo.CreateCatalogExportXml 'D102', @output output

exec dbo.XmlToFile @output, 'D:\websites\Bokrondellen (clean install)\import\ImportUtility\Sql\Catalog.xml'


