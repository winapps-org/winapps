use std::net::IpAddr;

use enum_dispatch::enum_dispatch;

use crate::{
    backend::{container::Container, manual::Manual},
    command::Command,
    config::App,
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
    pub fn get_backend(&'static self) -> &'static Backends {
        self.backend.get_or_init(|| {
            match (
                self.libvirt.enable,
                self.container.enable,
                self.manual.enable,
            ) {
                (true, _, _) => todo!(),
                (_, true, _) => Container::new(self).into(),
                (_, _, true) => Manual::new(self).into(),
                _ => unreachable!(),
            }
        })
    }

    pub fn get_host(&'static self) -> IpAddr {
        self.get_backend().get_host()
    }

    #[allow(dead_code)]
    fn get_installed_apps(&'static self) -> Result<Vec<App>> {
        let apps = Command::new("C:\\ExtractPrograms.ps1")
            .into_remote(self)
            .wait_with_output()?
            .lines()
            .filter_map(|line| {
                let mut split = line.split(";");

                match (split.next(), split.next(), split.next(), split.next()) {
                    (Some(id), Some(name), Some(path), Some(icon)) => Some(App {
                        id: id.to_string(),
                        name: name.to_string(),
                        win_exec: path.to_string(),
                        icon: Some(icon.to_string()),
                        icon_path: None,
                    }),
                    _ => None,
                }
            })
            .collect::<Vec<App>>();

        Ok(apps)
    }
}
