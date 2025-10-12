use parking_lot::RwLock;
use std::{net::IpAddr, str::FromStr};

use crate::{Backend, Config, Error, Result, ensure};

#[derive(Debug, Clone)]
pub struct Manual {
    config: &'static RwLock<Config>,
}

impl Manual {
    pub(crate) fn new() -> Self {
        Self {
            config: Config::get_lock(),
        }
    }
}

impl Backend for Manual {
    fn check_depends(&self) -> Result<()> {
        let config = self.config.read();

        ensure!(
            config.manual.enable,
            Error::Config("Manual backend is not enabled")
        );

        ensure!(
            !config.manual.host.is_empty(),
            Error::Config("Host shouldn't be empty")
        );

        ensure!(
            IpAddr::from_str(&config.manual.host).is_ok(),
            Error::Config("manual.host is not a valid IP address")
        );

        Ok(())
    }

    fn get_host(&self) -> IpAddr {
        let config = self.config.read();

        IpAddr::from_str(&config.manual.host)
            .expect("Manual host should be validated in check_depends")
    }
}
