use crate::{bail, Result};
use std::{fs, path::Path};

/// Check whether a directory exists and is a directory
/// If not, try creating it
pub fn path_ok(path: &Path) -> Result<()> {
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

/// Get the data dir and validates it exists
pub fn data_dir() -> Result<&'static Path> {
    let Some(data_dir) = dirs::data_local_dir() else {
        bail!("Could not determine $XDG_DATA_HOME")
    };

    let dir = data_dir.join("winapps").as_path();
    path_ok(dir)?;

    Ok(dir)
}

/// Get the icons dir and validates it exists
pub fn icons_dir() -> Result<&'static Path> {
    let dir = data_dir()?.join("icons").as_path();
    path_ok(dir)?;

    Ok(dir)
}

/// Get the XDG applications dir and validates it exists
pub fn desktop_dir() -> Result<&'static Path> {
    let Some(data_dir) = dirs::data_local_dir() else {
        bail!("Could not determine $XDG_DATA_HOME")
    };

    let dir = data_dir.join("applications").as_path();
    path_ok(dir)?;

    Ok(dir)
}
