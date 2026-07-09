use std::fs::{self, write};
use tracing::warn;

use crate::{Backends, Config, IntoResult, Result, dirs::config_dir};

impl Config {
    /// Reads the config from disk.
    pub fn try_new() -> Result<Box<Self>> {
        let config = Self::new();
        let config_path = config_dir()?.join("config.toml");

        let Ok(true) = config_path.try_exists() else {
            warn!("Config does not exist, writing default...");
            config.save()?;

            return Ok(Box::new(config));
        };

        let config_file = fs::read_to_string(config_path).into_result()?;
        let mut config: Self = toml::from_str(config_file.as_str()).into_result()?;

        config.backend = Backends::try_from_config(&config)?;

        Ok(Box::new(config))
    }

    pub fn save(&self) -> Result<()> {
        write(
            config_dir()?.join("config.toml"),
            toml::to_string_pretty(&self).into_result()?,
        )
        .into_result()
    }
}
