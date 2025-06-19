using Avalonia;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace WinAppsInstaller.ViewModels;

public partial class WelcomeViewModel : ViewModelBase
{
    [RelayCommand]
    private void StartInstall()
    {
        // Navigate to distro selection
        if (Application.Current is App { MainWindow.DataContext: MainWindowViewModel main })
        {
            main.CurrentViewModel = new DistroSelectionViewModel();
        }
    }
}