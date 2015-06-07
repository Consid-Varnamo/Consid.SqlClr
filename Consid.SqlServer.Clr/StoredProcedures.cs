using ICSharpCode.SharpZipLib.Core;
using ICSharpCode.SharpZipLib.Zip;
using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Mime;
using System.Text;
using System.Xml;

namespace Consid.SqlServer.Clr
{
    public class StoredProcedures
    {
        [SqlProcedure]
        public static void XmlToFile(SqlXml xmlData, SqlString fileName)
        {
            SqlPipe pipe = SqlContext.Pipe;

            try
            {
                XmlReader reader = xmlData.CreateReader();

                XmlWriterSettings settings = new XmlWriterSettings();
                settings.Indent = true;

                using (XmlWriter writer = XmlWriter.Create(fileName.Value, settings))
                {
                    while(reader.Read())
                    {
                        switch(reader.NodeType)
                        {
                            case XmlNodeType.Element :
                                writer.WriteStartElement(reader.Name);
                                if (reader.HasAttributes)
                                {
                                    writer.WriteAttributes(reader, true);
                                }
                                if (reader.IsEmptyElement)
                                    writer.WriteEndElement();
                                break;
                            case XmlNodeType.EndElement :
                                writer.WriteEndElement();
                                break;
                            case XmlNodeType.CDATA:
                                writer.WriteCData(reader.Value);
                                break;
                            case XmlNodeType.Text:
                                writer.WriteString(reader.Value);
                                break;
                            default :
                                throw new Exception(string.Format("Unhandled node type found: {0}", reader.NodeType));
                        }
                    }
                }
            }
            catch (Exception e)
            {
                pipe.Send(e.Message);
            }
        }

        [SqlProcedure]
        public static void ExportCatalogNode(SqlString catalogNodeCode, SqlString folderName)
        {
            Stopwatch sw = new Stopwatch();
            sw.Start();

            string xmlFileName = Path.Combine(folderName.Value, string.Format("Catalog-{0}-{1:yyyyMMdd}-{1:HHmm}-{2}.xml", catalogNodeCode, DateTime.Now, Dns.GetHostName()));
            string zipFileName = Path.Combine(folderName.Value, string.Format("Catalog-{0}-{1:yyyyMMdd}-{1:HHmm}-{2}.zip", catalogNodeCode, DateTime.Now, Dns.GetHostName()));

            try
            {
                using (SqlConnection conn = new SqlConnection("context connection=true"))
                {
                    SqlCommand cmd = new SqlCommand("CreateCatalogExportXml", conn);
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;

                    cmd.Parameters.Add(new SqlParameter("@CatalogNodeCode", SqlDbType.NVarChar) { Value = catalogNodeCode.Value });

                    SqlParameter output = cmd.Parameters.Add(new SqlParameter("@Output", SqlDbType.Xml) { Value = catalogNodeCode.Value });
                    output.Direction = ParameterDirection.Output;

                    SendMessage("{0} Loading entries...", sw.Elapsed);

                    conn.Open();
                    cmd.ExecuteNonQuery();
                    conn.Close();

                    XmlReader reader = ((SqlXml)output.SqlValue).CreateReader();
                    string entryCount = null;
                    string nodeCount = null;

                    reader.ReadToFollowing("Nodes");
                    if (reader.HasAttributes)
                    {
                        reader.MoveToFirstAttribute();
                        nodeCount = reader.Value;
                    }

                    reader.ReadToFollowing("Entries");
                    if (reader.HasAttributes)
                    {
                        reader.MoveToFirstAttribute();
                        entryCount = reader.Value;
                    }

                    SendMessage(new PluralFormatProvider(), "{0} Entries loaded sucessfully. Found {1:entry;entries} in {2:node;nodes}.", sw.Elapsed, entryCount, nodeCount);
                    SendMessage("{0} Creating xml file...", sw.Elapsed);

                    XmlToFile((SqlXml)output.SqlValue, xmlFileName);

                    SendMessage("{0} Xml file created sucessfully.", sw.Elapsed);
                    SendMessage("{0} Compressing file...", sw.Elapsed);

                    CreateCatalogPackage(xmlFileName, zipFileName);

                    SendMessage("{0} File compressed sucessfully.", sw.Elapsed);
                    SendMessage("{0} Removing Xml file...", sw.Elapsed);

                    if (File.Exists(xmlFileName))
                        File.Delete(xmlFileName);

                    SendMessage("{0} Xml file sucessfully deleted.", sw.Elapsed);
                    SendMessage("{0} Procedure completed sucessfully.", sw.Elapsed);
                }
            }
            catch (Exception e)
            {
                SqlContext.Pipe.Send(e.Message);
            }

            sw.Stop();
        }

        private static void CreateCatalogPackage(SqlString sourceFileName, SqlString zipFileName)
        {
            using (FileStream targetStream = new FileStream(zipFileName.Value, FileMode.Create))
            {
                using (ZipOutputStream zipStream = new ZipOutputStream(targetStream))
                {
                    zipStream.SetLevel(3);
                    zipStream.IsStreamOwner = true;

                    ZipEntry zipEntry = new ZipEntry("Catalog.xml");

                    zipStream.PutNextEntry(zipEntry);

                    using (FileStream sourceStream = new FileStream(sourceFileName.Value, FileMode.Open, FileAccess.Read))
                    {
                        byte[] buffer = new byte[4096];
                        int bytesRead = 0;

                        while ((bytesRead = sourceStream.Read(buffer, 0, 4096)) > 0)
                        {
                            zipStream.Write(buffer, 0, bytesRead);
                        }
                    }

                    zipStream.Flush();
                    zipStream.CloseEntry();
                    zipStream.Close();
                }
            }
        }

        private static void SendMessage(string format, params object[] args)
        {
            SendMessage(null, format, args);
        }

        private static void SendMessage(IFormatProvider provider, string format, params object[] args)
        {
            string msg;
            if (provider == null)
                msg = string.Format(format, args);
            else
                msg = string.Format(provider, format, args);

            using (SqlConnection conn = new SqlConnection("context connection=true"))
            {
                SqlCommand cmd;
                
                cmd = new SqlCommand(String.Format("raiserror(N'{0}', 0, 0) with nowait", msg), conn);

                conn.Open();
                SqlContext.Pipe.ExecuteAndSend(cmd);

            }
        }
    }
}
