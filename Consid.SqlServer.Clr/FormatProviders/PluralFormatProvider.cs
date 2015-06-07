using System;
using System.Collections.Generic;
using System.Text;

namespace Consid.SqlServer.Clr
{
    public class PluralFormatProvider : IFormatProvider, ICustomFormatter
    {
        public object GetFormat(Type formatType)
        {
            return this;
        }

        public string Format(string format, object arg, IFormatProvider formatProvider)
        {
            if (format == null)
                return arg.ToString();

            string[] forms = format.Split(';');

            int value;

            if (!(arg is string) || !int.TryParse((string)arg, out value))
            {
                value = (int)arg;
            }

            int form = value == 1 ? 0 : 1;
            return value.ToString() + " " + forms[form];
        }
    }
}

