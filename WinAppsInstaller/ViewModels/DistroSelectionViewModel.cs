using CommunityToolkit.Mvvm.ComponentModel;
using System.IO;

namespace WinAppsInstaller.ViewModels;

public partial class DistroSelectionViewModel : ViewModelBase
{
    [ObservableProperty]
    private string? _idLike;

    public DistroSelectionViewModel()
    {
        IdLike = ReadIdLike();
    }

    private string? ReadIdLike()
    {
        const string path = "/etc/os-release";
        if (!File.Exists(path))
            return null;

        foreach (var line in File.ReadAllLines(path))
        {
            if (line.StartsWith("ID_LIKE="))
            {
                return line["ID_LIKE=".Length..].Trim('"');
            }
        }

        return null;
    }
}