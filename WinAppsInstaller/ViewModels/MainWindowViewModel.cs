using CommunityToolkit.Mvvm.ComponentModel;

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
