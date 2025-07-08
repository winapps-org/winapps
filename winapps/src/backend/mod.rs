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

    fn as_remote_command(&self, command: Command) -> Command;

    fn get_installed_apps(&self) -> Result<Vec<App>>;
}

#[enum_dispatch(Backend)]
pub enum Backends {
    Container,
    Manual,
}

impl Config {
    pub fn get_backend(&'static self) -> Backends {
        assert!(self.libvirt.enable ^ self.container.enable ^ self.manual.enable);

        if self.libvirt.enable {
            todo!()
        }

        if self.container.enable {
            return Container::new(self).into();
        }

        if self.manual.enable {
            return Manual::new(self).into();
        }

        unreachable!()
    }

    pub fn get_host(&'static self) -> IpAddr {
        self.get_backend().get_host()
    }

    pub fn as_remote_command(&'static self, command: Command) -> Command {
        self.get_backend().as_remote_command(command)
    }

    fn get_installed_apps(&'static self) -> Result<Vec<App>> {
        Ok(self
            .as_remote_command(Command::new("C:\\ExtractPrograms.ps1"))
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
            .collect::<Vec<App>>())
    }
}
