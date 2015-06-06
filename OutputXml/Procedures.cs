using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Diagnostics;
using Microsoft.SqlServer.Server;
using System.Xml;



namespace SqlClr
{
    public partial class StoredProcedures
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
                doc.Save(fileName.Value);

                sw.Stop();

                output.Send(string.Format("The file {0} was saved sucessfully created ({1}).", fileName, sw.Elapsed));
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
