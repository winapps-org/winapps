use parking_lot::RwLock;
use std::{
    fs::{self, write},
    net::IpAddr,
    str::FromStr,
    sync::OnceLock,
};
use tracing::warn;

use crate::{dirs::config_dir, ensure, Config, Error, IntoResult, Result};

static CONFIG: OnceLock<RwLock<Config>> = OnceLock::new();

impl Config {
    /// Get a lock for the config, or an error if it couldn't be read
    pub fn try_get_lock() -> Result<&'static RwLock<Self>> {
        CONFIG.get_or_try_init(|| Ok(RwLock::new(Self::try_new()?)))
    }

    /// Get a lock for the config
    /// Panics: if the lock is not initialized
    pub fn get_lock() -> &'static RwLock<Self> {
        CONFIG.get().expect("The lock is not initialized")
    }

    /// Reads the config from disk.
    fn try_new() -> Result<Self> {
        let config = Self::new();
        let config_path = config_dir()?.join("config.toml");

        let Ok(true) = config_path.try_exists() else {
            warn!("Config does not exist, writing default...");
            config.save()?;

            return Ok(config);
        };

        let config_file = fs::read_to_string(config_path).into_result()?;
        let config: Self = toml::from_str(config_file.as_str()).into_result()?;

        ensure!(
            [config.libvirt.enable, config.container.enable, config.manual.enable]
                .into_iter()
                .filter(|enabled| *enabled)
                .count() == 1,
            Error::Config("More than one backend enabled, please set only one of libvirt.enable, container.enable, and manual.enable")
        );

        ensure!(
            config.manual.enable && IpAddr::from_str(&config.manual.host).is_err(),
            Error::Config("Please set manual.host to a valid IP address")
        );

        Ok(config)
    }

    pub fn save(&self) -> Result<()> {
        write(
            config_dir()?.join("config.toml"),
            toml::to_string_pretty(&self).into_result()?,
        )
        .into_result()
    }
}
