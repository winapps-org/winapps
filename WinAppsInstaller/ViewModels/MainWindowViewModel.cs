using CommunityToolkit.Mvvm.ComponentModel;
using WinAppsInstaller.ViewModels;

namespace WinAppsInstaller.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    [ObservableProperty]
    private ViewModelBase _currentViewModel;

    public MainWindowViewModel()
    {
        CurrentViewModel = new WelcomeViewModel();
    }
}
