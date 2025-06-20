using System;
using System.Globalization;
using Avalonia.Data.Converters;
using Avalonia.Media;

namespace WinAppsInstaller.Converters
{
    public class BoolToBrushConverter : IValueConverter
    {
        public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        {
            if (value is bool b)
                return b ? Brushes.Green : Brushes.Red;

            return Brushes.Gray;
        }

        public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture) =>
            throw new NotSupportedException();
    }
}
