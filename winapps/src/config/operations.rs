use crate::config::Config;
use crate::errors::WinappsError;
use crate::{error, error_from, map_err};
use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{LazyLock, RwLock, RwLockReadGuard};

fn path_ok(path: &Path) -> Result<(), WinappsError> {
    if let Ok(false) = path.try_exists() {
        if let Err(e) = fs::create_dir_all(path) {
            return Err(error_from!(
                e,
                "Failed to create config directory {:?}",
                path
            ));
        }
    }

    if !path.is_dir() {
        return Err(error!("Config directory {:?} is not a directory", path));
    }

    Ok(())
}

static CONFIG: LazyLock<RwLock<Config>> = LazyLock::new(|| RwLock::new(Config::new()));

impl Config {
    pub fn get() -> RwLockReadGuard<'static, Self> {
        CONFIG.read().unwrap()
    }

    fn get_path(path: Option<&str>) -> Result<PathBuf, WinappsError> {
        let path = match (path, dirs::config_dir()) {
            (Some(path), _) => Ok(PathBuf::from(path)),
            (None, Some(path)) => Ok(path),
            _ => Err(error!(
                "Could not find $XDG_CONFIG_HOME and no config path specified"
            )),
        }
        .map(|path| path.join("winapps").join("config.toml"))?;

        let parent = path.parent().unwrap();
        path_ok(parent)?;

        Ok(path)
    }

    pub fn load(&mut self, path: Option<&str>) -> Result<(), WinappsError> {
        let config_path = Self::get_path(path)?;

        if config_path.exists() {
            self.save(path)?;
            return Ok(());
        }

        let config_file = map_err!(
            fs::read_to_string(config_path),
            "Failed to read configuration file"
        )?;

        let config: Self = map_err!(
            toml::from_str(config_file.as_str()),
            "Failed to parse configuration file"
        )?;

        if !(config.libvirt.enable ^ config.container.enable ^ config.manual.enable) {
            return Err(error!("More than one backend enabled, please set only one of libvirt.enable, container.enable, and manual.enable"));
        }

        let mut global_config = CONFIG.write().unwrap();
        *global_config = config;

        Ok(())
    }

    pub fn save(&self, path: Option<&str>) -> Result<(), WinappsError> {
        let config_path = Self::get_path(path)?;
        let serialized_config = toml::to_string(&self)
            .map_err(|e| error_from!(e, "Failed to serialize configuration"))?;

        let mut config_file = match config_path.try_exists() {
            Ok(true) => map_err!(
                File::open(&config_path),
                "Failed to open configuration file"
            ),
            Ok(false) => map_err!(
                File::create(&config_path),
                "Failed to open configuration file"
            ),
            Err(e) => Err(error_from!(
                e,
                "Something went wrong whilst checking whether the config exists"
            )),
        }?;

        if let Err(e) = write!(config_file, "{}", serialized_config) {
            return Err(error_from!(e, "Failed to write configuration file"));
        }

        Ok(())
    }

    pub fn get_data_path(path: Option<&str>) -> Result<PathBuf, WinappsError> {
        let path = match (path, dirs::data_dir()) {
            (Some(path), _) => Ok(PathBuf::from(path)),
            (None, Some(path)) => Ok(path),
            _ => Err(error!(
                "Could not find $XDG_DATA_HOME and no data path specified"
            )),
        }
        .map(|path| path.join("winapps"))?;

        let parent = path.parent().unwrap();
        path_ok(parent)?;

        Ok(path)
    }
}
