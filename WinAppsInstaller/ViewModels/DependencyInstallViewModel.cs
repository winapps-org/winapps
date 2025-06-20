using System.Text;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using Avalonia.Threading;
using WinAppsInstaller.Models;

namespace WinAppsInstaller.ViewModels;

public partial class DependencyInstallViewModel : ViewModelBase
{
    private readonly StringBuilder _outputBuilder = new();

    [ObservableProperty]
    private string? _installOutput;

    [ObservableProperty]
    private bool _isInstallDone;

    public bool CanInstall => !IsInstallDone;

    partial void OnIsInstallDoneChanged(bool value)
    {
        OnPropertyChanged(nameof(CanInstall));
    }


    public DependencyInstallViewModel()
    {
        // Show commands immediately on view model creation
        _ = LoadInstallCommandsAsync();
    }

    private void AppendOutput(string text)
    {
        Dispatcher.UIThread.Post(() =>
        {
            _outputBuilder.AppendLine(text);
            InstallOutput = _outputBuilder.ToString();
        });
    }

    private Task LoadInstallCommandsAsync()
    {
        IsInstallDone = false;
        _outputBuilder.Clear();

        var idLike = AppState.Instance.IdLike?.ToLowerInvariant() ?? "";

        string commands = idLike switch
        {
            var s when s.Contains("debian") || s.Contains("ubuntu") => @"
echo ""Checking if backports are enabled for freerdp3-x11...""
if ! grep -r ""buster-backports"" /etc/apt/sources.list* > /dev/null; then
  echo ""Backports not found. You might want to enable backports to get freerdp3-x11.""
  echo ""See: https://backports.debian.org/Instructions/""
fi

echo ""Updating package lists...""
sudo apt update

echo ""Installing packages...""
sudo apt install -y curl dialog freerdp3-x11 git iproute2 libnotify-bin netcat-openbsd
",

            var s when s.Contains("fedora") || s.Contains("rhel") => @"
sudo dnf install -y curl dialog freerdp git iproute libnotify nmap-ncat
",

            var s when s.Contains("arch") => @"
sudo pacman -Syu --needed -y curl dialog freerdp git iproute2 libnotify openbsd-netcat
",

            var s when s.Contains("opensuse") => @"
sudo zypper install -y curl dialog freerdp git iproute2 libnotify-tools netcat-openbsd
",

            var s when s.Contains("gentoo") => @"
sudo emerge --ask=n net-misc/curl dev-util/dialog net-misc/freerdp:3 dev-vcs/git sys-apps/iproute2 x11-libs/libnotify net-analyzer/openbsd-netcat
",

            _ => "No install commands available for your Linux distribution."
        };

        AppendOutput(commands.Trim());

        IsInstallDone = true;
        return Task.CompletedTask;
    }
}
