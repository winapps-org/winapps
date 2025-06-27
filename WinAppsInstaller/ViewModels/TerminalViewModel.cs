using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using WinAppsInstaller.Models;

namespace WinAppsInstaller.ViewModels;

public partial class TerminalViewModel : ViewModelBase
{
    private Process? _shellProcess;
    private StreamWriter? _stdin;

    [ObservableProperty]
    private string currentCommand = "";

    public ObservableCollection<StyledLine> TerminalLines { get; } = new();

    private readonly string _prompt;

    public TerminalViewModel()
    {
        var user = Environment.UserName;
        var host = Environment.MachineName;
        _prompt = $"{user}@{host}:~$";

        StartShell();
    }

    private void StartShell()
    {
        var psi = new ProcessStartInfo
        {
            FileName = "/bin/bash",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
            WorkingDirectory = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)
        };

        _shellProcess = new Process { StartInfo = psi };
        _shellProcess.OutputDataReceived += (_, e) => AddLine(e.Data, "LightGreen");
        _shellProcess.ErrorDataReceived += (_, e) => AddLine(e.Data, "Tomato");

        _shellProcess.Start();
        _stdin = _shellProcess.StandardInput;

        _shellProcess.BeginOutputReadLine();
        _shellProcess.BeginErrorReadLine();
    }

    private void AddLine(string? line, string color)
    {
        if (string.IsNullOrWhiteSpace(line)) return;

        Avalonia.Threading.Dispatcher.UIThread.Post(() =>
        {
            TerminalLines.Add(new StyledLine
            {
                Text = line,
                Color = color
            });
        });
    }

    [RelayCommand]
    private async Task SendCommandAsync()
    {
        if (string.IsNullOrWhiteSpace(CurrentCommand) || _stdin == null) return;

        // Echo prompt line
        TerminalLines.Add(new StyledLine
        {
            Text = $"{_prompt} {CurrentCommand}",
            Color = "Cyan"
        });

        await _stdin.WriteLineAsync(CurrentCommand);
        await _stdin.FlushAsync();

        CurrentCommand = string.Empty;
    }
}
