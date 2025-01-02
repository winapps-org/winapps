use derive_new::new;
use serde::{Deserialize, Serialize};

mod apps;
mod operations;

#[derive(new, Debug, Deserialize, Serialize, Clone)]
pub struct Config {
    #[new(value = "AuthConfig::new()")]
    pub auth: AuthConfig,
    #[new(value = "ContainerConfig::new()")]
    pub container: ContainerConfig,
    #[new(value = "LibvirtConfig::new()")]
    pub libvirt: LibvirtConfig,
    #[new(value = "ManualConfig::new()")]
    pub manual: ManualConfig,
    #[new(value = "FreerdpConfig::new()")]
    pub freerdp: FreerdpConfig,
    #[new(value = "Vec::new()")]
    pub installed_apps: Vec<App>,
    #[new(value = "false")]
    pub debug: bool,
}

#[derive(new, Debug, Deserialize, Serialize, Clone)]
pub struct AuthConfig {
    #[new(value = "\"Docker\".to_string()")]
    pub username: String,
    #[new(value = "\"\".to_string()")]
    pub password: String,
    #[new(value = "\"\".to_string()")]
    pub domain: String,
}

#[derive(new, Debug, Deserialize, Serialize, Clone)]
pub struct ContainerConfig {
    #[new(value = "true")]
    pub enable: bool,
    #[new(value = "false")]
    pub enable_podman: bool,
    #[new(value = "\"WinApps\".to_string()")]
    pub container_name: String,
}

#[derive(new, Debug, Deserialize, Serialize, Clone)]
pub struct LibvirtConfig {
    #[new(value = "false")]
    pub enable: bool,
    #[new(value = "\"RDPWindows\".to_string()")]
    pub vm_name: String,
}

#[derive(new, Debug, Deserialize, Serialize, Clone)]
pub struct ManualConfig {
    #[new(value = "false")]
    pub enable: bool,
    #[new(value = "\"127.0.0.1\".to_string()")]
    pub host: String,
}

#[derive(new, Debug, Deserialize, Serialize, Clone)]
pub struct FreerdpConfig {
    #[new(value = r#"vec![
            "/cert:tofu".to_string(),
            "/sound".to_string(),
            "/microphone".to_string(),
            "/dynamic-resolution".to_string(),
            "+auto-reconnect".to_string(),
            "+clipboard".to_string(),
            "+home-drive".to_string(),
        ]"#)]
    pub extra_args: Vec<String>,
    #[new(value = "\"xfreerdp\".to_string()")]
    pub executable: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct App {
    pub id: String,
    pub name: String,
    pub win_exec: String,
}
