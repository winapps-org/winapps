use std::net::IpAddr;

use enum_dispatch::enum_dispatch;

use crate::{
    backend::{container::Container, manual::Manual},
    command::Command,
    config::{App, AppKind},
    Config, Result,
};

mod container;
mod manual;

#[enum_dispatch]
pub trait Backend {
    fn check_depends(&self) -> Result<()>;

    fn get_host(&self) -> IpAddr;
}

#[enum_dispatch(Backend)]
#[derive(Debug, Clone)]
pub enum Backends {
    Container,
    Manual,
}

impl Config {
    pub fn get_backend(&self) -> &Backends {
        self.backend.get_or_init(|| {
            match (
                self.libvirt.enable,
                self.container.enable,
                self.manual.enable,
            ) {
                (true, _, _) => todo!(),
                (_, true, _) => Container::new().into(),
                (_, _, true) => Manual::new().into(),
                _ => unreachable!(),
            }
        })
    }

    pub fn get_host(&self) -> IpAddr {
        self.get_backend().get_host()
    }

    pub fn get_available_apps(&self) -> Result<Vec<App>> {
        let apps = Command::new("C:\\ExtractPrograms.ps1")
            .into_remote(self)
            .wait_with_output()?
            .lines()
            .filter_map(|line| {
                let mut split = line.split(";").map(|part| part.trim());

                match (split.next(), split.next(), split.next(), split.next()) {
                    (Some(id), Some(name), Some(path), Some(icon)) => Some(App {
                        id: id.to_string(),
                        name: name.to_string(),
                        win_exec: path.to_string(),
                        kind: AppKind::FromBase64(icon.to_string()),
                    }),
                    _ => None,
                }
            })
            .collect::<Vec<App>>();

        Ok(apps)
    }
}
