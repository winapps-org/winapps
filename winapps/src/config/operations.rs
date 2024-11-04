use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{LazyLock, RwLock, RwLockReadGuard};

use crate::{bail, Config, Error, IntoResult, Result};

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

static CONFIG: LazyLock<RwLock<Config>> = LazyLock::new(|| RwLock::new(Config::new()));

impl Config {
    pub fn get() -> RwLockReadGuard<'static, Self> {
        CONFIG.read().unwrap()
    }

    fn get_path(path: Option<&str>) -> Result<PathBuf> {
        let path = match (path, dirs::config_dir()) {
            (Some(path), _) => Ok(PathBuf::from(path)),
            (None, Some(path)) => Ok(path),
            _ => "Could not find $XDG_CONFIG_HOME and no config path specified".into_result(),
        }
        .map(|path| path.join("winapps").join("config.toml"))?;
        
        let parent = path.parent().unwrap();
        path_ok(parent)?;

        Ok(path)
    }

    pub fn load(&self, path: Option<&str>) -> Result<()> {
        let config_path = Self::get_path(path)?;

        if !config_path.exists() {
            return self.save(path);
        }
        
        let config_file = fs::read_to_string(config_path).into_result()?;
        let config: Self = toml::from_str(config_file.as_str()).into_result()?;

        if !(config.libvirt.enable ^ config.container.enable ^ config.manual.enable) {
            bail!(Error::Config("More than one backend enabled, please set only one of libvirt.enable, container.enable, and manual.enable"));
        }

        let mut global_config = CONFIG.write().unwrap();
        *global_config = config;

        Ok(())
    }

    pub fn save(&self, path: Option<&str>) -> Result<()> {
        let config_path = Self::get_path(path)?;
        let serialized_config = toml::to_string(&self).into_result()?;

        let mut config_file = match config_path.try_exists() {
            Ok(true) => File::open(&config_path).into_result(),
            Ok(false) => File::create(&config_path).into_result(),
            Err(e) => Error::Io(e).into(),
        }?;

        if let Err(e) = write!(config_file, "{}", serialized_config) {
            bail!(e);
        }

        Ok(())
    }

    pub fn get_data_path(path: Option<&str>) -> Result<PathBuf> {
        let path = match (path, dirs::data_dir()) {
            (Some(path), _) => Ok(PathBuf::from(path)),
            (None, Some(path)) => Ok(path),
            _ => "Could not find $XDG_DATA_HOME and no data path specified".into_result(),
        }
        .map(|path| path.join("winapps"))?;

        let parent = path.parent().unwrap();
        path_ok(parent)?;

        Ok(path)
    }
}
