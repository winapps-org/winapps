use crate::{Result, bail};
use std::{
    fs,
    path::{Path, PathBuf},
};

/// Check whether a directory exists and is a directory
/// If not, try creating it
pub fn path_ok(path: &Path) -> Result<()> {
    if let Ok(false) = path.try_exists()
        && let Err(e) = fs::create_dir_all(path)
    {
        bail!(e);
    }

    if !path.is_dir() {
        bail!("Config directory {:?} is not a directory", path);
    }

    Ok(())
}

/// Get the data dir and validates it exists
pub fn data_dir() -> Result<PathBuf> {
    let Some(data_dir) = dirs::data_dir().map(|path| path.join("winapps")) else {
        bail!("Could not determine $XDG_DATA_HOME")
    };

    path_ok(data_dir.as_path())?;
    Ok(data_dir)
}

/// Get the config dir and validates it exists
pub fn config_dir() -> Result<PathBuf> {
    let Some(config_dir) = dirs::config_dir().map(|path| path.join("winapps")) else {
        bail!("Could not determine $XDG_CONFIG_HOME")
    };

    path_ok(config_dir.as_path())?;
    Ok(config_dir)
}

/// Get the icons dir and validates it exists
pub fn icons_dir() -> Result<PathBuf> {
    let Some(data_dir) = dirs::data_dir().map(|path| path.join("icons")) else {
        bail!("Could not determine $XDG_DATA_HOME")
    };

    path_ok(data_dir.as_path())?;
    Ok(data_dir)
}

/// Get the XDG applications dir and validates it exists
pub fn desktop_dir() -> Result<PathBuf> {
    let Some(data_dir) = dirs::data_dir().map(|path| path.join("applications")) else {
        bail!("Could not determine $XDG_DATA_HOME")
    };

    path_ok(data_dir.as_path())?;
    Ok(data_dir)
}
