mod docker;

use crate::backend::docker::Docker;
use crate::config::Config;
use crate::errors::Result;

pub trait Backend {
    fn check_depends(&self) -> Result<()>;

    fn get_host(&self) -> String;
}

impl Config {
    pub fn get_backend(&self) -> impl Backend + Sized {
        assert!(self.libvirt.enable ^ self.container.enable ^ self.manual.enable);

        if self.libvirt.enable {
            todo!()
        }

        if self.container.enable {
            if self.container.enable_podman {
                todo!()
            }

            return Docker::new();
        }

        if self.manual.enable {
            todo!()
        }

        unreachable!()
    }
}
