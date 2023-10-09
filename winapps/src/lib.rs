pub mod errors;
pub mod freerdp;
pub mod quickemu;

use crate::errors::WinappsError;
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
use tracing::{info, warn};

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
            warn!("Couldn't read XDG_CONFIG_HOME, falling back to ~/.config");
            unwrap_or_panic!(home_dir(), "Couldn't find the home directory").join(".config/winapps")
        }
    };

    let path = Path::new(path.unwrap_or(unwrap_or_panic!(
        default.to_str(),
        "Couldn't convert path {:?} to string",
        default
    )));

    if !path.exists() {
        info!("{:?} does not exist! Creating...", path);
        fs::create_dir_all(path).expect("Failed to create directory");
    }

    if !path.is_dir() {
        error!("Config directory {:?} is not a directory", path).panic();
    }

    path.join("config.toml")
}

pub fn load_config(path: Option<&str>) -> Config {
    let config = Config::new();
    let config_path = get_config_file(path);

    if !config_path.exists() {
        unwrap_or_panic!(
            save_config(&config, path),
            "Failed to write default configuration"
        );

        return config;
    }

    let config_file = unwrap_or_panic!(
        fs::read_to_string(config_path),
        "Failed to read configuration file"
    );

    let config: Config = unwrap_or_panic!(
        toml::from_str(config_file.as_str()),
        "Failed to parse configuration file",
    );

    config
}

pub fn save_config(config: &Config, path: Option<&str>) -> Result<(), WinappsError> {
    let config_path = get_config_file(path);
    let serialized_config = unwrap_or_panic!(
        toml::to_string(&config),
        "Failed to serialize configuration"
    );

    let mut config_file = match config_path.exists() {
        true => unwrap_or_panic!(
            File::open(&config_path),
            "Failed to open configuration file"
        ),
        false => unwrap_or_panic!(
            File::create(&config_path),
            "Failed to create configuration file"
        ),
    };

    if let Err(e) = write!(config_file, "{}", serialized_config) {
        return Err(error_from!(e, "Failed to write configuration file"));
    }

    Ok(())
}

pub fn get_data_dir() -> PathBuf {
    let path = match env::var("XDG_DATA_HOME") {
        Ok(dir) => PathBuf::from(dir).join("winapps"),
        Err(_) => {
            warn!("Couldn't read XDG_DATA_HOME, falling back to ~/.local/share");
            unwrap_or_panic!(home_dir(), "Couldn't find the home directory")
                .join(".local/share/winapps")
        }
    };

    if !path.exists() {
        let dir = path.clone();
        info!(
            "Data directory {:?} does not exist! Creating...",
            dir.to_str()
        );
        fs::create_dir_all(dir).expect("Failed to create directory");
    }

    if !path.is_dir() {
        error!("Data directory {:?} is not a directory", path).panic();
    }

    path
}
