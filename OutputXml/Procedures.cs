using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Xml;



namespace SqlClr
{
    public partial class StoredProcedures
    {
        [SqlProcedure]
        public static void OutputXml(SqlXml xmlData, SqlString fileName)
        {
            XmlDocument doc = new XmlDocument();
            SqlPipe output = SqlContext.Pipe;

            try
            {
                doc.LoadXml(xmlData.Value);
                doc.Save(fileName.Value);
                output.Send(string.Format("The file {0} was saved sucessfully.", fileName));
            }
            catch (Exception e)
            {
                output.Send(e.Message);
            }
        }

        [SqlProcedure]
        public static void HelloWorld()
        {
            SqlContext.Pipe.Send("Hello world!");
        }

    }
}
