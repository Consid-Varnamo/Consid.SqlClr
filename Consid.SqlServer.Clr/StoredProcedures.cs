using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
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
            SqlPipe pipe = SqlContext.Pipe;

            Stopwatch sw = new Stopwatch();
            sw.Start();

            try
            {
                doc.LoadXml(xmlData.Value);

                XmlDeclaration declaration = doc.CreateXmlDeclaration("1.0", "utf-8", null);
                doc.InsertBefore(declaration, doc.DocumentElement);

                doc.Save(fileName.Value);

                sw.Stop();

                pipe.Send(string.Format("The file '{0}' was sucessfully created({1}).", fileName, sw.Elapsed));
            }
            catch (Exception e)
            {
                pipe.Send(e.Message);
            }
        }

        [SqlProcedure]
        public static void ExportCatalogNode (SqlString catalogNodeCode, SqlString fileName)
        {
            SqlPipe pipe = SqlContext.Pipe;

            try
            {
                using (SqlConnection conn = new SqlConnection("context connection=true"))
                {
                    SqlCommand cmd = new SqlCommand("CreateCatalogExportXml", conn);
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;

                    cmd.Parameters.Add(new SqlParameter("@CatalogNodeCode", SqlDbType.NVarChar) { Value = catalogNodeCode.Value });
                    SqlParameter output = cmd.Parameters.Add(new SqlParameter("@Output", SqlDbType.Xml) { Value = catalogNodeCode.Value });
                    output.Direction = ParameterDirection.Output;

                    conn.Open();
                    cmd.ExecuteNonQuery();
                    conn.Close();
                    XmlToFile((SqlXml)output.SqlValue, fileName);
                }
            }
            catch (Exception e)
            {
                pipe.Send(e.Message);
            }
        }
    }
}
