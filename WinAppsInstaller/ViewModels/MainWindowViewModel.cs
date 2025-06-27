using CommunityToolkit.Mvvm.ComponentModel;

namespace WinAppsInstaller.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    [ObservableProperty]
    private ViewModelBase _currentViewModel;

    public MainWindowViewModel()
    {
        // Here is starting ViewModel that will be displayed first in MainWindow.
        CurrentViewModel = new TerminalViewModel();
    }
}
