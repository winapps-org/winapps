use crate::{
    Config, Error, Result,
    config::{App, AppKind},
    dirs::{desktop_dir, icons_dir},
    ensure,
};
use base64::{Engine, prelude::BASE64_STANDARD};
use std::{fmt::Display, fs, os::unix::fs::PermissionsExt};
use tracing::{debug, warn};

impl PartialEq for App {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Eq for App {}

impl std::hash::Hash for App {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.id.hash(state);
    }
}

impl Display for App {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.write_fmt(format_args!("{} ({})", self.name, self.win_exec))
    }
}

impl App {
    fn try_as_existing(&mut self) -> Result<&mut Self> {
        ensure!(
            self.id
                .chars()
                .all(|c| c.is_alphanumeric() || c == '-' || c == '_'),
            Error::Message(format!("Invalid app ID: {}", self.id))
        );

        match &self.kind {
            AppKind::FromBase64(base64) => {
                let path = icons_dir()?.join(format!("{}.png", self.id));
                fs::write(path.clone(), BASE64_STANDARD.decode(base64)?)?;

                self.kind = AppKind::Existing;

                Ok(self)
            }
            AppKind::Existing => Ok(self),
        }
    }

    fn try_as_desktop_file(&mut self) -> Result<String> {
        debug!("Writing desktop icon for {}", self.id);

        match &self.kind {
            AppKind::FromBase64(_) => self.try_as_existing()?.try_as_desktop_file(),
            AppKind::Existing => Ok(format!(
                "[Desktop Entry]
Name={}
Exec=winapps run {}
Terminal=false
Type=Application
Icon={}
StartupWMClass={}
Comment={} (WinApps)",
                self.name,
                self.id,
                icons_dir()?
                    .join(format!("{}.png", self.id))
                    .to_string_lossy(),
                self.id,
                self.name
            )),
        }
    }

    pub fn link(mut self, config: &mut Config) -> Result<()> {
        self.try_as_existing()?;

        let path = desktop_dir()?.join(format!("{}.desktop", self.id));

        fs::write(&path, self.try_as_desktop_file()?)?;
        fs::set_permissions(&path, PermissionsExt::from_mode(0o750))?;

        if !config.linked_apps.contains_key(&self.id) {
            debug!("Writing app {} to config", self.id);

            config.linked_apps.insert(self.id.clone(), self);
            config.save()?;
        }

        Ok(())
    }

    pub fn unlink(self, config: &mut Config) -> Result<()> {
        let path = desktop_dir()?.join(format!("{}.desktop", self.id));

        fs::remove_file(&path).unwrap_or_else(|_| {
            warn!(
                "Could not delete desktop file for {} ({})",
                self.id,
                path.to_string_lossy()
            )
        });

        debug!("Removing app {} to config", self.id);

        config.linked_apps.remove_entry(&self.id);
        config.save()
    }
}
