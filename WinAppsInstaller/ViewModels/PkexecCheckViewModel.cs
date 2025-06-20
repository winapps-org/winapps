using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Diagnostics;
using System.IO;
using Avalonia;
using WinAppsInstaller.Models;

namespace WinAppsInstaller.ViewModels;

public partial class PkexecCheckViewModel : ViewModelBase
{
    private readonly MainWindowViewModel _mainWindow;

    [ObservableProperty]
    private string? statusMessage;

    [ObservableProperty]
    private bool isPkexecInstalled;

    [ObservableProperty]
    private bool showInstallButton;

    [ObservableProperty]
    private bool showContinueButton;

    public PkexecCheckViewModel(MainWindowViewModel mainWindow)
    {
        _mainWindow = mainWindow;
        CheckPkexec();
    }

    private void CheckPkexec()
    {
        var process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = "/bin/bash",
                Arguments = "-c \"command -v pkexec\"",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            }
        };

        process.Start();
        var output = process.StandardOutput.ReadToEnd().Trim();
        process.WaitForExit();

        if (!string.IsNullOrWhiteSpace(output) && File.Exists(output))
        {
            StatusMessage = "✅ pkexec is already installed.";
            IsPkexecInstalled = true;
            ShowInstallButton = false;
            ShowContinueButton = true;
        }
        else
        {
            StatusMessage = "⚠️ pkexec is not installed.";
            IsPkexecInstalled = false;
            ShowInstallButton = true;
            ShowContinueButton = false;
        }
    }

    [RelayCommand]
    private void InstallPkexec()
    {
        var idLike = AppState.Instance.IdLike?.ToLowerInvariant() ?? "";

        string? installCmd = idLike switch
        {
            var s when s.Contains("debian") || s.Contains("ubuntu") => "sudo apt install -y policykit-1",
            var s when s.Contains("fedora") => "sudo dnf install -y polkit",
            var s when s.Contains("arch") => "sudo pacman -S --needed --noconfirm polkit",
            var s when s.Contains("opensuse") => "sudo zypper install -y polkit",
            var s when s.Contains("gentoo") => "sudo emerge polkit",
            _ => null
        };

        if (installCmd is null)
        {
            StatusMessage = "Unsupported distro. Please install 'polkit' manually using your package manager.";
            return;
        }

        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "x-terminal-emulator",
                Arguments = $"-e \"{installCmd}\"",
                UseShellExecute = false
            });
        }
        catch
        {
            // Fallback terminal options
            string[] fallbackTerms = { "gnome-terminal", "konsole", "xterm", "lxterminal", "mate-terminal" };
            foreach (var term in fallbackTerms)
            {
                try
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = term,
                        Arguments = $"-e \"{installCmd}\"",
                        UseShellExecute = false
                    });
                    break;
                }
                catch { }
            }
        }

        StatusMessage = "Install launched in terminal. Please complete it, then click 'Continue'.";
        ShowContinueButton = true;
    }

    [RelayCommand]
    private void ContinueAfterInstall()
    {
        CheckPkexec();
        if (IsPkexecInstalled)
        {
            if (Application.Current is App { MainWindow.DataContext: MainWindowViewModel main })
            {
                main.CurrentViewModel = new DependencyInstallViewModel(); // or whatever the next step is
            }
        }
        else
        {
            StatusMessage = "pkexec still not detected. Ensure installation completed.";
        }
    }
}
