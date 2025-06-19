using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Diagnostics;
using System.IO;
using WinAppsInstaller.Models;

namespace WinAppsInstaller.ViewModels;

public partial class PkexecCheckViewModel : ViewModelBase
{
    [ObservableProperty]
    private string? statusMessage;

    [ObservableProperty]
    private bool isPkexecInstalled;

    [ObservableProperty]
    private bool showInstallButton;

    public PkexecCheckViewModel()
    {
        CheckPkexec();
    }

    private void CheckPkexec()
    {
        // Try to find pkexec
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
            StatusMessage = "pkexec is already installed.";
            IsPkexecInstalled = true;
            ShowInstallButton = false;
        }
        else
        {
            StatusMessage = "pkexec is not installed.";
            IsPkexecInstalled = false;
            ShowInstallButton = true;
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
            var s when s.Contains("nixos") => null, // handled differently
            _ => null
        };

        if (installCmd is null)
        {
            StatusMessage = "Cannot auto-install pkexec on this distro. Please install 'polkit' manually.";
            return;
        }

        // Open terminal with install command
        Process.Start(new ProcessStartInfo
        {
            FileName = "x-terminal-emulator", // fallback terminal
            Arguments = $"-e \"{installCmd}\"",
            UseShellExecute = false
        });

        StatusMessage = "Attempted to install pkexec. Please try again after the installation completes.";
    }
}
