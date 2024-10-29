mod docker;

use crate::backend::docker::Docker;
use crate::config::Config;

pub trait Backend {
    fn check_depends(&self, config: &Config);

    fn start(&self, config: &Config);

    fn get_host(&self, config: &Config) -> String;
}

impl Config {
    pub fn get_backend(&self) -> impl Backend + Sized {
        assert!(self.libvirt.enable || self.container.enable || self.manual.enable);

        if self.libvirt.enable {
            todo!()
        }

        if self.container.enable {
            if self.container.enable_podman {
                todo!()
            }

            return Docker {};
        }

        if self.manual.enable {
            todo!()
        }

        unreachable!()
    }
}
