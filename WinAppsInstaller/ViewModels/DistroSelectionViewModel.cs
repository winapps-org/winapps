using CommunityToolkit.Mvvm.ComponentModel;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Avalonia;
using CommunityToolkit.Mvvm.Input;
using WinAppsInstaller.Models;

namespace WinAppsInstaller.ViewModels;

public partial class DistroSelectionViewModel : ViewModelBase
{
    private static readonly string[] SupportedFamilies =
    [
        "debian", "ubuntu", "fedora", "arch", "opensuse", "gentoo", "nixos"
    ];

    [ObservableProperty]
    private string? _idLike;

    [ObservableProperty]
    private bool _isSupported;

    [ObservableProperty]
    private string? _statusMessage;

    public DistroSelectionViewModel()
    {
        LoadDistroInfo();
    }

    private void LoadDistroInfo()
    {
        const string path = "/etc/os-release";
        if (!File.Exists(path))
        {
            StatusMessage = "Cannot find /etc/os-release. Unsupported system.";
            IsSupported = false;
            return;
        }

        var idLikeLine = File.ReadLines(path)
            .FirstOrDefault(l => l.StartsWith("ID_LIKE="));

        if (idLikeLine == null)
        {
            StatusMessage = "Could not detect distro family.";
            IsSupported = false;
            return;
        }

        var raw = idLikeLine["ID_LIKE=".Length..].Trim('"');
        IdLike = raw;

        var detectedFamilies = raw.Split(' ', StringSplitOptions.RemoveEmptyEntries);

        var matched = detectedFamilies
            .Intersect(SupportedFamilies, StringComparer.OrdinalIgnoreCase)
            .FirstOrDefault();

        if (matched != null)
        {
            StatusMessage = $"Detected supported distro family: {matched}";
            IsSupported = true;
        }
        else
        {
            StatusMessage = $"Detected unsupported distro: {raw}";
            IsSupported = false;
        }

        // This saves value of ID_LIKE to AppState.cs Model.
        AppState.Instance.IdLike = IdLike;
        // You can access ID_LIKE value later by using code bellow in any ViewModel.
        // var idLike = AppState.Instance.IdLike;
    }

    [RelayCommand]
    private void Continue()
    {
        // You can navigate to the next step here, for example:
        if (Application.Current is App { MainWindow.DataContext: MainWindowViewModel main })
        {
            main.CurrentViewModel = new PkexecCheckViewModel(main); // or whatever the next step is
        }
    }
}
