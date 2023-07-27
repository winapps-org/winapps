use home::home_dir;
use std::path::PathBuf;
use std::process::exit;
use std::process::Command;

pub(crate) fn get_data_dir() -> PathBuf {
    let home = home_dir().expect("Could not find the home path!");
    let data_dir = home.join(".local/share/winapps");

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

pub fn run_vm() {
    let data_dir = get_data_dir();

    let output = match Command::new("quickemu")
        .current_dir(data_dir)
        .arg("--vm")
        .arg("windows-10-22H2.conf")
        .spawn()
        .unwrap()
        .wait_with_output()
    {
        Ok(o) => o,
        Err(e) => {
            println!("Failed to execute quickemu: {}", e);
            println!("Please make sure quickemu is installed and in your PATH");
            exit(1);
        }
    };

    println!("{}", String::from_utf8_lossy(&output.stdout));
}
