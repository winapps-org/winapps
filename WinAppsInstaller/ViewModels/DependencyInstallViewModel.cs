using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading.Tasks;
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

    [RelayCommand]
    private async Task InstallDependencies()
    {
        IsInstallDone = false;
        InstallOutput = "";

        var idLike = AppState.Instance.IdLike?.ToLowerInvariant() ?? "";

        try
        {
            // Enable Debian backports if needed
            if (idLike.Contains("debian") && IsDebianOnly())
                EnableDebianBackports();

            string? installCmd = idLike switch
            {
                var s when s.Contains("debian") || s.Contains("ubuntu") =>
                    "apt install -y curl dialog freerdp3-x11 git iproute2 libnotify-bin netcat-openbsd",

                var s when s.Contains("fedora") || s.Contains("rhel") =>
                    "dnf install -y curl dialog freerdp git iproute libnotify nmap-ncat",

                var s when s.Contains("arch") =>
                    "pacman -Syu --needed --noconfirm curl dialog freerdp git iproute2 libnotify openbsd-netcat",

                var s when s.Contains("opensuse") =>
                    "zypper install -y curl dialog freerdp git iproute2 libnotify-tools netcat-openbsd",

                var s when s.Contains("gentoo") =>
                    "emerge --ask=n net-misc/curl dev-util/dialog net-misc/freerdp:3 dev-vcs/git sys-apps/iproute2 x11-libs/libnotify net-analyzer/openbsd-netcat",

                _ => null
            };

            if (string.IsNullOrWhiteSpace(installCmd))
            {
                InstallOutput = "No install command generated. Either unsupported distro or all packages already installed.";
                return;
            }

            var fullCommand = $"pkexec bash -c \"{installCmd}\"";
            InstallOutput = $"Running command: {fullCommand}\n";


            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "/bin/bash",
                    Arguments = $"-c \"{fullCommand}\"",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                },
                EnableRaisingEvents = true
            };

            process.OutputDataReceived += (s, e) =>
            {
                if (!string.IsNullOrWhiteSpace(e.Data))
                    AppendLine(e.Data);
            };

            process.ErrorDataReceived += (s, e) =>
            {
                if (!string.IsNullOrWhiteSpace(e.Data))
                    AppendLine("[ERR] " + e.Data);
            };

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            await process.WaitForExitAsync();

            AppendLine("Installation finished.");
            IsInstallDone = true;
        }
        catch (Exception ex)
        {
            AppendLine($"Installation failed: {ex.Message}");
        }
    }

    private void AppendLine(string text)
    {
        InstallOutput += text + Environment.NewLine;
    }

    private bool IsDebianOnly()
    {
        var lines = File.ReadAllLines("/etc/os-release");
        foreach (var line in lines)
        {
            if (line.StartsWith("ID="))
            {
                var id = line["ID=".Length..].Trim('"');
                return id.Equals("debian", StringComparison.OrdinalIgnoreCase);
            }
        }
        return false;
    }

    private string? GetDebianCodename()
    {
        var lines = File.ReadAllLines("/etc/os-release");
        foreach (var line in lines)
        {
            if (line.StartsWith("VERSION_CODENAME="))
                return line["VERSION_CODENAME=".Length..].Trim('"');
        }
        return null;
    }

    private void EnableDebianBackports()
    {
        var codename = GetDebianCodename();
        if (string.IsNullOrWhiteSpace(codename))
        {
            AppendLine("Could not determine Debian codename for backports setup.");
            return;
        }

        var listPath = $"/etc/apt/sources.list.d/{codename}-backports.list";
        if (File.Exists(listPath))
            return; // Already added

        var backportsLine = $"deb https://deb.debian.org/debian {codename}-backports main";
        var command = $"echo \"{backportsLine}\" | tee {listPath} && apt update";

        var process = Process.Start(new ProcessStartInfo
        {
            FileName = "/bin/bash",
            Arguments = $"-c \"pkexec bash -c '{command}'\"",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        });

        process?.WaitForExit();

        AppendLine($"Backports repository added for Debian ({codename}).");
    }
}
