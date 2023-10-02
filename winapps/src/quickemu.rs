use crate::{get_data_dir, save_config, Config};
use std::fs;
use std::process::exit;
use std::process::Command;

pub fn create_vm(mut config: Config) {
    let data_dir = get_data_dir();

    let output = match Command::new("quickget")
        .current_dir(data_dir)
        .arg("windows")
        .arg("10")
        .output()
    {
        Ok(o) => o,
        Err(e) => {
            println!("Failed to execute quickget: {}", e);
            println!("Please make sure quickget is installed and in your PATH");
            exit(1);
        }
    };

    config.vm.name = "windows-10-22H2".to_string();
    config.vm.short_name = "windows-10".to_string();

    save_config(&config, None).expect("Failed to save config, VM will not start properly");

    println!("{}", String::from_utf8_lossy(&output.stdout));
}

pub fn start_vm(config: Config) {
    let data_dir = get_data_dir();

    let command = match Command::new("quickemu")
        .current_dir(data_dir)
        .args([
            "--vm",
            &format!("{}.conf", config.vm.name),
            "--display",
            "none",
        ])
        .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            println!("Failed to execute quickemu: {}", e);
            println!("Please make sure quickemu is installed and in your PATH");
            exit(1);
        }
    };

    let output = match command.wait_with_output() {
        Ok(o) => o,
        Err(e) => {
            println!("Failed to gather output from quickemu: {}", e);
            println!("Please make sure quickemu is installed and in your PATH");
            exit(1);
        }
    };

    println!("{}", String::from_utf8_lossy(&output.stdout));
}

pub fn kill_vm(config: Config) {
    let data_dir = get_data_dir();

    match fs::read_to_string(
        data_dir.join(format!("{}/{}.pid", config.vm.short_name, config.vm.name)),
    ) {
        Ok(pid) => {
            let pid = pid.trim();

            println!("Killing VM with PID {}", pid);

            match Command::new("kill").arg(pid).spawn() {
                Ok(_) => (),
                Err(e) => {
                    println!("Failed to kill VM: {}", e);
                    exit(1);
                }
            }
        }
        Err(e) => {
            println!("Failed to read PID file: {}", e);
            exit(1);
        }
    }
}
