use std::{
    fs,
    fs::File,
    io::Write,
    path::{Path, PathBuf},
    sync::OnceLock,
};
use tracing::warn;

use crate::{bail, Config, Error, IntoResult, Result};

impl Config {
    /// Reads the config from disk.
    ///
    /// Panics if this is called a second time after already returning an `Ok`.
    pub fn load() -> Result<&'static Config> {
        static CONFIG: OnceLock<Config> = OnceLock::new();

        CONFIG.get_or_try_init::<fn() -> Result<Config>, Error>(|| {
            let config = Config::new();
            let config_path = Self::get_path()?;

            let Ok(true) = config_path.try_exists() else {
                warn!("Config does not exist, writing default...");
                config.save()?;

                return Ok(config);
            };

            let config_file = fs::read_to_string(config_path).into_result()?;
            let config: Self = toml::from_str(config_file.as_str()).into_result()?;

            if !(config.libvirt.enable ^ config.container.enable ^ config.manual.enable) {
                bail!(Error::Config("More than one backend enabled, please set only one of libvirt.enable, container.enable, and manual.enable"));
            }

            Ok(config)
        })
    }

    fn path_ok(path: &Path) -> Result<()> {
        if let Ok(false) = path.try_exists() {
            if let Err(e) = fs::create_dir_all(path) {
                bail!(e);
            }
        }

        if !path.is_dir() {
            bail!("Config directory {:?} is not a directory", path);
        }

        Ok(())
    }

    fn get_path() -> Result<PathBuf> {
        let path = match dirs::config_dir() {
            Some(path) => Ok(path),
            None => "Could not find $XDG_CONFIG_HOME and no config path specified".into_result(),
        }
        .map(|path| path.join("winapps").join("config.toml"))?;

        let parent = path.parent().unwrap();
        Self::path_ok(parent)?;

        Ok(path)
    }

    pub fn save(&self) -> Result<()> {
        let config_path = Self::get_path()?;
        let serialized_config = toml::to_string_pretty(&self).into_result()?;

        let mut config_file = match config_path.try_exists() {
            Ok(true) => File::open(&config_path).into_result(),
            Ok(false) => File::create(&config_path).into_result(),
            Err(e) => Error::Io(e).into(),
        }?;

        if let Err(e) = write!(config_file, "{serialized_config}") {
            bail!(e);
        }

        Ok(())
    }

    pub fn get_data_path() -> Result<PathBuf> {
        let path = match dirs::data_dir() {
            Some(path) => Ok(path),
            None => "Could not find $XDG_DATA_HOME and no data path specified".into_result(),
        }
        .map(|path| path.join("winapps"))?;

        let parent = path.parent().unwrap();
        Self::path_ok(parent)?;

        Ok(path)
    }
}
