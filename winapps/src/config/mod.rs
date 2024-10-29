use derive_new::new;
use serde::{Deserialize, Serialize};

mod apps;
mod operations;

#[derive(new, Debug, Deserialize, Serialize)]
pub struct Config {
    #[new(value = "AuthConfig::new()")]
    pub auth: AuthConfig,
    #[new(value = "ContainerConfig::new()")]
    pub container: ContainerConfig,
    #[new(value = "LibvirtConfig::new()")]
    pub libvirt: LibvirtConfig,
    #[new(value = "ManualConfig::new()")]
    pub manual: ManualConfig,
    #[new(value = "Vec::new()")]
    pub installed_apps: Vec<App>,
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct AuthConfig {
    #[new(value = "\"Docker\".to_string()")]
    pub username: String,
    #[new(value = "\"\".to_string()")]
    pub password: String,
    #[new(value = "\"\".to_string()")]
    pub domain: String,
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct ContainerConfig {
    #[new(value = "true")]
    pub enable: bool,
    #[new(value = "false")]
    pub enable_podman: bool,
    #[new(value = "\"WinApps\".to_string()")]
    pub container_name: String,
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct LibvirtConfig {
    #[new(value = "false")]
    pub enable: bool,
    #[new(value = "\"RDPWindows\".to_string()")]
    pub vm_name: String,
}

#[derive(new, Debug, Deserialize, Serialize)]
pub struct ManualConfig {
    #[new(value = "false")]
    pub enable: bool,
    #[new(value = "\"127.0.0.1\".to_string()")]
    pub host: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct App {
    pub id: String,
    pub name: String,
    pub win_exec: String,
}
