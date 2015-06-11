using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Globalization;
using System.Text;

namespace Consid.SqlServer.Clr
{
    public class Functions
    {
        [SqlFunction]
        public static string RemoveDiacritics(string originalString)
        {
            String data = originalString.Normalize(NormalizationForm.FormD);
            StringBuilder sb = new StringBuilder();

            for (int i = 0; i < data.Length; i++)
            {
                Char c = data[i];
                if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                    sb.Append(c);
            }

            return sb.ToString();
        }
    }
}
