using System;
using System.Diagnostics;
using System.IO;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using WinAppsInstaller.Models;

namespace WinAppsInstaller.ViewModels;

public partial class DependencyInstallViewModel : ViewModelBase
{
    [ObservableProperty]
    private string? _installOutput;

    [ObservableProperty]
    private bool _isInstallDone;

    // New property to control button enable state
    public bool CanInstall => !IsInstallDone;

    // Notify UI that CanInstall changed when IsInstallDone changes
    partial void OnIsInstallDoneChanged(bool value)
    {
        OnPropertyChanged(nameof(CanInstall));
    }

    [RelayCommand]
    private void InstallDependencies()
    {
        IsInstallDone = false;
        InstallOutput = "";

        var idLike = AppState.Instance.IdLike?.ToLowerInvariant() ?? "";

        string? installCmd = idLike switch
        {
            var s when s.Contains("debian") || s.Contains("ubuntu") =>
                "sudo apt install -y curl dialog freerdp3-x11 git iproute2 libnotify-bin netcat-openbsd",

            var s when s.Contains("fedora") || s.Contains("rhel") =>
                "sudo dnf install -y curl dialog freerdp git iproute libnotify nmap-ncat",

            var s when s.Contains("arch") =>
                "sudo pacman -Syu --needed --noconfirm curl dialog freerdp git iproute2 libnotify openbsd-netcat",

            var s when s.Contains("opensuse") =>
                "sudo zypper install -y curl dialog freerdp git iproute2 libnotify-tools netcat-openbsd",

            var s when s.Contains("gentoo") =>
                "sudo emerge --ask=n net-misc/curl dev-util/dialog net-misc/freerdp:3 dev-vcs/git sys-apps/iproute2 x11-libs/libnotify net-analyzer/openbsd-netcat",

            _ => null
        };

        if (string.IsNullOrWhiteSpace(installCmd))
        {
            InstallOutput = "No install command available for this distribution.";
            return;
        }

        string? terminal = DetectTerminal();

        if (terminal == null)
        {
            InstallOutput = "No compatible terminal emulator found.";
            return;
        }

        string terminalArgs = terminal switch
        {
            "gnome-terminal" => $"-- bash -c \"{installCmd}; echo; echo 'Press any key to exit...'; read -n 1\"",
            "konsole"        => $"-e bash -c \"{installCmd}; echo; echo 'Press any key to exit...'; read -n 1\"",
            "xterm"          => $"-e bash -c \"{installCmd}; echo; echo 'Press any key to exit...'; read -n 1\"",
            "xfce4-terminal" => $"--hold -e bash -c \"{installCmd}\"",
            "tilix"          => $"-- bash -c \"{installCmd}; echo; echo 'Press any key to exit...'; read -n 1\"",
            "lxterminal"     => $"-e bash -c \"{installCmd}; echo; echo 'Press any key to exit...'; read -n 1\"",
            "mate-terminal"  => $"-- bash -c \"{installCmd}; echo; echo 'Press any key to exit...'; read -n 1\"",
            "alacritty"      => $"-e bash -c \"{installCmd}; echo; echo 'Press any key to exit...'; read -n 1\"",
            _ => throw new ArgumentOutOfRangeException()
        };

        try
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = terminal,
                    Arguments = terminalArgs,
                    UseShellExecute = false
                }
            };

            process.Start();
            InstallOutput = $"Launched terminal with command:\n{installCmd}";
            IsInstallDone = true;
        }
        catch (Exception ex)
        {
            InstallOutput = $"Failed to launch terminal: {ex.Message}";
        }
    }

    private string? DetectTerminal()
    {
        string[] terminals =
        {
            "gnome-terminal",
            "xfce4-terminal",
            "konsole",
            "xterm",
            "tilix",
            "lxterminal",
            "mate-terminal",
            "alacritty"
        };

        foreach (var term in terminals)
        {
            if (File.Exists($"/usr/bin/{term}"))
                return term;
        }

        return null;
    }
}
