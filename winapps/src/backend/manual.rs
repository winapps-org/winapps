use std::net::IpAddr;

use crate::{Backend, Config, Error, Result, ensure};

#[derive(Debug, Clone, Copy)]
pub struct Manual;

impl Backend for Manual {
    fn check_depends(self, config: &Config) -> Result<()> {
        ensure!(
            config.manual.enable,
            Error::Config("Manual backend is not enabled")
        );

        Ok(())
    }

    fn get_host(self, config: &Config) -> IpAddr {
        config.manual.host
    }
}
