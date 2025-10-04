use crate::{
    config::{App, AppKind},
    dirs::{desktop_dir, icons_dir},
    Config, Result,
};
use base64::{prelude::BASE64_STANDARD, Engine};
use std::{fmt::Display, fs::write};

impl PartialEq for App {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Display for App {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!("{} ({})", self.name, self.win_exec))
    }
}

impl App {
    fn try_as_existing(&mut self) -> Result<&mut Self> {
        match self.kind.clone() {
            AppKind::Detected(base64) => {
                let path = icons_dir()?.join(format!("{}.png", self.id));
                write(path.clone(), BASE64_STANDARD.decode(base64)?)?;

                self.kind = AppKind::Existing(path);

                Ok(self)
            }
            AppKind::Existing(_) => Ok(self),
        }
    }

    fn try_as_desktop_file(&mut self, exec: String) -> Result<String> {
        match &self.kind {
            AppKind::Detected(_) => self.try_as_existing()?.try_as_desktop_file(exec),
            AppKind::Existing(path) => Ok(format!(
                "[Desktop Entry]
Name={}
Exec={exec}
Terminal=false
Type=Application
Icon={}
StartupWMClass={}
Comment={}",
                self.name,
                path.to_string_lossy(),
                self.id,
                self.name
            )),
        }
    }

    pub fn link(mut self, config: &mut Config, exec: String) -> Result<()> {
        self.try_as_existing()?;

        write(
            desktop_dir()?.join(format!("{}.desktop", self.id)),
            self.try_as_desktop_file(exec)?,
        )?;

        if !config.linked_apps.contains(&self) {
            config.linked_apps.push(self)
        }

        config.save()?;

        Ok(())
    }
}

impl Config {
    pub fn find_linked_app(&self, id: String) -> Option<&App> {
        self.linked_apps.iter().find(|app| app.id == id)
    }
}
