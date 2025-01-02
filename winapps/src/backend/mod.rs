use std::net::IpAddr;

use enum_dispatch::enum_dispatch;

use crate::{
    backend::{container::Container, manual::Manual},
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
}
