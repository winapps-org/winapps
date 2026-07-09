use std::net::IpAddr;

use enum_dispatch::enum_dispatch;

use crate::{
    Config, Error, Result,
    backend::{container::Container, manual::Manual},
    bail,
    command::Command,
    config::{App, AppKind},
};

mod container;
mod manual;

#[enum_dispatch]
pub trait Backend {
    fn check_depends(self, config: &Config) -> Result<()>;

    fn get_host(self, config: &Config) -> IpAddr;
}

#[enum_dispatch(Backend)]
#[derive(Debug, Clone, Copy)]
pub enum Backends {
    Container(Container),
    Manual(Manual),
}

impl Default for Backends {
    fn default() -> Self {
        Container.into()
    }
}

impl Backends {
    pub fn try_from_config(config: &Config) -> Result<Self> {
        Ok(
            match (
                config.libvirt.enable,
                config.container.enable,
                config.manual.enable,
            ) {
                (true, false, false) => todo!(),
                (false, true, false) => Container.into(),
                (false, false, true) => Manual.into(),
                _ => bail!(Error::Config(
                    "More than one backend enabled, please set only one of libvirt.enable, container.enable, and manual.enable"
                )),
            },
        )
    }
}

impl Config {
    pub fn backend_check_depends(&self) -> Result<()> {
        self.backend.check_depends(self)
    }

    pub fn get_host(&self) -> IpAddr {
        self.backend.get_host(self)
    }

    fn normalize_app_id(input: String) -> String {
        input
            .strip_suffix(".exe")
            .map(|s| s.to_string())
            .unwrap_or(input)
    }

    pub fn get_available_apps(&self) -> Result<Vec<App>> {
        // todo: stronger parsing, better errors
        let apps = Command::new("C:\\ExtractPrograms.ps1")
            .into_remote(self)
            .wait_with_output()?
            .lines()
            .filter_map(|line| {
                let mut split = line.split(";").map(|part| part.trim());

                match (split.next(), split.next(), split.next(), split.next()) {
                    (Some(id), Some(name), Some(path), Some(icon)) => Some(App {
                        id: Self::normalize_app_id(id.to_string()),
                        name: name.to_string(),
                        win_exec: path.to_string(),
                        kind: AppKind::FromBase64(icon.to_string()),
                    }),

                    // Skip ids ending in .dll for now
                    (Some(id), _, _, _) if id.ends_with(".dll") => None,
                    _ => None,
                }
            })
            .collect::<Vec<App>>();

        Ok(apps)
    }
}
