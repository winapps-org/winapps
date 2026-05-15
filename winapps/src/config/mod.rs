use derive_new::new;
use serde::{Deserialize, Deserializer, Serialize};
use std::{collections::HashMap, net::IpAddr};

use crate::Backends;

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
    #[new(value = "HashMap::new()")]
    #[serde(deserialize_with = "deserialize_apps")]
    pub linked_apps: HashMap<String, App>,
    #[new(value = "false")]
    pub debug: bool,

    #[serde(skip)]
    #[new(value = "Backends::default()")]
    pub(crate) backend: Backends,
}

#[derive(new, Debug, Deserialize, Serialize, Clone)]
pub struct AuthConfig {
    #[new(value = "\"MyWindowsUser\".to_string()")]
    pub username: String,
    #[new(value = "\"MyWindowsPassword\".to_string()")]
    pub password: String,
    #[new(value = "2222")]
    pub ssh_port: u16,
    #[new(value = "3389")]
    pub rdp_port: u16,
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
    #[new(value = "std::net::Ipv4Addr::LOCALHOST.into()")]
    pub host: IpAddr,
}

#[derive(new, Debug, Deserialize, Serialize, Clone)]
pub struct FreerdpConfig {
    #[new(value = r#"vec![
            "/cert:tofu".to_string(),
            "/sound".to_string(),
            "/microphone".to_string(),
            "+auto-reconnect".to_string(),
            "+home-drive".to_string(),
        ]"#)]
    pub extra_args: Vec<String>,
    #[new(value = "\"xfreerdp\".to_string()")]
    pub executable: String,
    #[serde(deserialize_with = "deserialize_rdp_scale")]
    #[new(value = "100")]
    pub rdp_scale: u8,
}

#[derive(Debug, Default, Deserialize, Serialize, Clone)]
pub enum AppKind {
    FromBase64(String),
    #[default]
    Existing,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct App {
    pub name: String,
    pub win_exec: String,

    #[serde(skip)]
    pub id: String,

    #[serde(skip)]
    pub kind: AppKind,
}

fn deserialize_rdp_scale<'de, D>(deserializer: D) -> Result<u8, D::Error>
where
    D: Deserializer<'de>,
{
    let scale = u8::deserialize(deserializer)?;

    match scale {
        100 | 140 | 180 => Ok(scale),
        _ => Err(serde::de::Error::custom(format!(
            "Found invalid rdp_scale {scale}, only 100, 140 and 180 are supported"
        ))),
    }
}

fn deserialize_apps<'de, D>(deserializer: D) -> Result<HashMap<String, App>, D::Error>
where
    D: Deserializer<'de>,
{
    let mut apps = HashMap::<String, App>::deserialize(deserializer)?;

    for (id, app) in apps.iter_mut() {
        app.id = id.clone();
    }

    Ok(apps)
}
