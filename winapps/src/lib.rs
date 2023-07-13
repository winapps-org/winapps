use derive_new::new;
use home::home_dir;
use serde::{Deserialize, Serialize};
use std::io::Write;
use std::{
    fs::{self, File},
    path::Path,
};

#[derive(new, Debug, Deserialize, Serialize)]
pub struct Config {
    #[new(value = "HostConfig::new()")]
    host: HostConfig,
    #[new(value = "RemoteConfig::new()")]
    rdp: RemoteConfig,
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct HostConfig {
    #[new(value = "\"X11\".to_string()")]
    display: String,
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct RemoteConfig {
    #[new(value = "\"RDPWindows\".to_string()")]
    host: String,
    #[new(value = "\"WORKGROUP\".to_string()")]
    domain: String,
    #[new(value = "\"RDPUser\".to_string()")]
    username: String,
    #[new(value = "\"RDPPass\".to_string()")]
    password: String,
}

pub trait RemoteClient {
    fn check_depends(&self) -> bool {
        panic!("Dependency check not implemented!");
    }

    fn load_config(&self, path: &str);

    fn run_app(&self, app: &str);
}

pub fn load_config(path: Option<&str>) -> Config {
    let home = home_dir().expect("Could not find the home path!");
    let default = &format!("{}{}", home.to_str().unwrap(), "/.config/winapps/");
    let path = Path::new(path.unwrap_or(default));
    let config = Config::new();

    if !path.exists() {
        println!("{:?} does not exist! Creating...", path.to_str());
        fs::create_dir_all(path).expect("Failed to create directory");
    }

    let config_file = path.join("config.toml");

    if !config_file.exists() {
        let mut config_file =
            File::create(&config_file).expect("Failed to create configuration file");

        let gen_config = toml::to_string(&config).except("Failed to generate default configuration");
        write!(config_file, "{}", gen_config).expect("Failed to write configuration file");
    }

    let config_file = fs::read_to_string(config_file).expect("Failed to read configuration file");
    let config: Config = toml::from_str(config_file.as_str()).expect("Failed to parse the configuration");

    config
}

pub fn add(left: usize, right: usize) -> usize {
    left + right
}
