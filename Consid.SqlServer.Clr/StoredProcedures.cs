using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Diagnostics;
using System.Text;
using System.Xml;

namespace Consid.SqlServer.Clr
{
    public class StoredProcedures
    {
        [SqlProcedure]
        public static void XmlToFile(SqlXml xmlData, SqlString fileName)
        {
            XmlDocument doc = new XmlDocument();
            SqlPipe output = SqlContext.Pipe;

            Stopwatch sw = new Stopwatch();
            sw.Start();

            try
            {
                doc.LoadXml(xmlData.Value);

                XmlDeclaration declaration = doc.CreateXmlDeclaration("1.0", "utf-8", null);
                doc.InsertBefore(declaration, doc.DocumentElement);

                doc.Save(fileName.Value);

                sw.Stop();

                output.Send(string.Format("The file '{0}' was sucessfully created({1}).", fileName, sw.Elapsed));
            }
            catch (Exception e)
            {
                output.Send(e.Message);
            }
        }
    }
}
