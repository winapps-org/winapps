use parking_lot::RwLock;
use std::{net::IpAddr, str::FromStr};

use crate::{ensure, Backend, Config, Error, Result};

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

        assert!(config.manual.enable);
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

        // SAFETY: When the config is read, we check that this is a valid IP
        // We assume that the program will never write this field,
        // so it should always be valid at this point
        IpAddr::from_str(&config.manual.host).unwrap()
    }
}
