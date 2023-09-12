use home::home_dir;
use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::exit;
use std::process::Command;

pub fn get_data_dir() -> PathBuf {
    let home = home_dir().expect("Could not find the home path!");

    let data_dir = match env::var("XDG_DATA_HOME") {
        Ok(dir) => PathBuf::from(dir).join("winapps"),
        Err(_) => {
            println!("Couldn't read XDG_DATA_HOME, falling back to ~/.local/share");
            home.join(".local/share/winapps")
        }
    };

    if !data_dir.exists() {
        let dir = data_dir.clone();
        println!(
            "Data directory {:?} does not exist! Creating...",
            dir.to_str()
        );
        std::fs::create_dir_all(dir).expect("Failed to create directory");
    }

    if !data_dir.is_dir() {
        panic!("Data directory {:?} is not a directory!", data_dir.to_str());
    }

    data_dir
}

pub fn create_vm() {
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

    println!("{}", String::from_utf8_lossy(&output.stdout));
}

pub fn start_vm() {
    let data_dir = get_data_dir();

    let command = match Command::new("quickemu")
        .current_dir(data_dir)
        .args(["--vm", "windows-10-22H2.conf", "--display", "none"])
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

pub fn kill_vm() {
    let data_dir = get_data_dir();

    match fs::read_to_string(data_dir.join("windows-10/windows-10-22H2.pid")) {
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
