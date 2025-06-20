using CommunityToolkit.Mvvm.ComponentModel;
using System;
using System.IO;
using System.Linq;
using Avalonia.Media;
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

    public IBrush StatusForeground => IsSupported ? Brushes.Green : Brushes.Red;

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
            OnPropertyChanged(nameof(StatusForeground));
            return;
        }

        var lines = File.ReadLines(path).ToList();
        var idLikeLine = lines.FirstOrDefault(l => l.StartsWith("ID_LIKE="));
        var raw = idLikeLine?["ID_LIKE=".Length..]?.Trim('"');

        if (string.IsNullOrWhiteSpace(raw))
        {
            // Fallback to ID=
            var idLine = lines.FirstOrDefault(l => l.StartsWith("ID="));
            raw = idLine?["ID=".Length..]?.Trim('"');
        }

        if (string.IsNullOrWhiteSpace(raw))
        {
            StatusMessage = "Could not detect distro family.";
            IsSupported = false;
            OnPropertyChanged(nameof(StatusForeground));
            return;
        }

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

        OnPropertyChanged(nameof(StatusForeground));

        // Save detected family in AppState
        AppState.Instance.IdLike = IdLike;
    }

    [RelayCommand]
    private void Continue()
    {
        if (Application.Current is App { MainWindow.DataContext: MainWindowViewModel main })
        {
            main.CurrentViewModel = new DependencyInstallViewModel();
        }
    }
}
