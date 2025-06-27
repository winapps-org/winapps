using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Markup.Xaml;

namespace WinAppsInstaller.Views;

public partial class TerminalView : UserControl
{
    public TerminalView()
    {
        InitializeComponent();
    }

    private void TextBox_OnKeyDown(object? sender, KeyEventArgs e)
    {
        if (DataContext is not ViewModels.TerminalViewModel vm)
            return;

        if (e.Key == Key.Enter)
        {
            vm.SendCommandCommand.Execute(null);
            e.Handled = true;
        }
    }
}