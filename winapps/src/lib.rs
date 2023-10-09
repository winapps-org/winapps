pub mod quickemu;

use derive_new::new;
use home::home_dir;
use serde::{Deserialize, Serialize};
use std::io::Write;
use std::path::PathBuf;
use std::{
    env,
    fs::{self, File},
    path::Path,
};

pub mod freerdp;

pub trait RemoteClient {
    fn check_depends(&self, config: Config);

    fn run_app(&self, config: Config, app: Option<&String>);
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct Config {
    #[new(value = "HostConfig::new()")]
    host: HostConfig,
    #[new(value = "RemoteConfig::new()")]
    rdp: RemoteConfig,
    #[new(value = "VmConfig::new()")]
    vm: VmConfig,
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct VmConfig {
    #[new(value = "\"windows-10\".to_string()")]
    short_name: String,
    #[new(value = "\"windows-10-22H2\".to_string()")]
    name: String,
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct HostConfig {
    #[new(value = "\"X11\".to_string()")]
    display: String,
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct RemoteConfig {
    #[new(value = "\"127.0.0.1\".to_string()")]
    host: String,
    #[new(value = "\"WORKGROUP\".to_string()")]
    domain: String,
    #[new(value = "\"Quickemu\".to_string()")]
    username: String,
    #[new(value = "\"quickemu\".to_string()")]
    password: String,
}

pub fn get_config_file(path: Option<&str>) -> PathBuf {
    let default = match env::var("XDG_CONFIG_HOME") {
        Ok(dir) => PathBuf::from(dir).join("winapps"),
        Err(_) => {
            println!("Couldn't read XDG_CONFIG_HOME, falling back to ~/.config");
            home_dir()
                .expect("Could not find the home path!")
                .join(".config/winapps")
        }
    };

    let path = Path::new(path.unwrap_or(default.to_str().unwrap()));

    if !path.exists() {
        println!("{:?} does not exist! Creating...", path);
        fs::create_dir_all(path).expect("Failed to create directory");
    }

    if !path.is_dir() {
        panic!("Config directory {:?} is not a directory!", path);
    }

    path.join("config.toml")
}

pub fn load_config(path: Option<&str>) -> Config {
    let config = Config::new();
    let config_path = get_config_file(path);

    if !config_path.exists() {
        save_config(&config, path).expect("Failed to write default configuration");
        return config;
    }

    let config_file = fs::read_to_string(config_path).expect("Failed to read configuration file");
    let config: Config =
        toml::from_str(config_file.as_str()).expect("Failed to parse the configuration");

    config
}

pub fn save_config(config: &Config, path: Option<&str>) -> std::io::Result<()> {
    let config_path = get_config_file(path);
    let serialized_config = toml::to_string(&config).expect("Failed to serialize configuration");

    let mut config_file = match config_path.exists() {
        true => File::open(&config_path).expect("Failed to open configuration file"),
        false => File::create(&config_path).expect("Failed to create configuration file"),
    };

    write!(config_file, "{}", serialized_config)
}

pub fn get_data_dir() -> PathBuf {
    let data_dir = match env::var("XDG_DATA_HOME") {
        Ok(dir) => PathBuf::from(dir).join("winapps"),
        Err(_) => {
            println!("Couldn't read XDG_DATA_HOME, falling back to ~/.local/share");
            home_dir()
                .expect("Could not find the home path!")
                .join(".local/share/winapps")
        }
    };

    if !data_dir.exists() {
        let dir = data_dir.clone();
        println!(
            "Data directory {:?} does not exist! Creating...",
            dir.to_str()
        );
        fs::create_dir_all(dir).expect("Failed to create directory");
    }

    if !data_dir.is_dir() {
        panic!("Data directory {:?} is not a directory!", data_dir);
    }

    data_dir
}

pub fn add(left: usize, right: usize) -> usize {
    left + right
}
