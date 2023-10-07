use crate::{get_data_dir, save_config, unwrap_or_exit, Config};
use std::fs;
use std::process::Command;
use tracing::info;

pub fn create_vm(mut config: Config) {
    let data_dir = get_data_dir();

    let output = unwrap_or_exit!(
        Command::new("quickget")
            .current_dir(data_dir)
            .arg("windows")
            .arg("10")
            .output(),
        "Failed to execute quickget: \n\
        Please make sure quickget is installed and in your PATH"
    );

    config.vm.name = "windows-10-22H2".to_string();
    config.vm.short_name = "windows-10".to_string();

    unwrap_or_exit!(save_config(&config, None), "Failed to save config");

    println!("{}", String::from_utf8_lossy(&output.stdout));
}

pub fn start_vm(config: Config) {
    let data_dir = get_data_dir();

    let command = unwrap_or_exit!(
        Command::new("quickemu")
            .current_dir(data_dir)
            .args([
                "--vm",
                &format!("{}.conf", config.vm.name),
                "--display",
                "none",
            ])
            .spawn(),
        "Failed to execute quickemu: \n\
        Please make sure quickemu is installed and in your PATH"
    );

    let output = unwrap_or_exit!(
        command.wait_with_output(),
        "Failed to gather output from quickemu / stdout"
    );

    println!("{}", String::from_utf8_lossy(&output.stdout));
}

pub fn kill_vm(config: Config) {
    let data_dir = get_data_dir();

    let pid = unwrap_or_exit!(
        fs::read_to_string(
            data_dir.join(format!("{}/{}.pid", config.vm.short_name, config.vm.name)),
        ),
        "Failed to read PID file, is the VM running and the config correct?"
    );

    info!("Killing VM with PID {}", pid);

    unwrap_or_exit!(
        Command::new("kill").arg(pid).spawn(),
        "Failed to kill VM (execute kill)"
    );
}
