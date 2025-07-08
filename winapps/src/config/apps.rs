use crate::{
    config::App,
    dirs::{desktop_dir, icons_dir},
    Config, Result,
};
use base64::{prelude::BASE64_STANDARD, Engine};
use std::fs::write;

impl PartialEq for App {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl App {
    /// Panics: If `self.icon_path` is `None`
    /// Make sure to write the icon to a file by now
    /// and populate `icon_path`
    /// This should be normally done by now
    fn as_desktop_file(&self, exec: String) -> String {
        format!(
            "[Desktop Entry]
Name={}
Exec={exec}
Terminal=false
Type=Application
Icon={}
StartupWMClass={}
Comment={}",
            self.name,
            self.icon_path.clone().unwrap(),
            self.id,
            self.name
        )
    }

    /// Panics: If `self.icon` is `None` and `write_icon` is `true` OR if `self.icon_path` is `None` and `write_icon` is `false` (or if both are `None`)
    /// At this point in the program, that shouldn't normally be the case
    pub fn link(self, config: &mut Config, exec: String, write_icon: bool) -> Result<()> {
        if write_icon {
            write(
                icons_dir()?.join(format!("{}.png", self.id)),
                BASE64_STANDARD.decode(self.icon.clone().unwrap())?,
            )?;
        }

        write(
            desktop_dir()?.join(format!("{}.desktop", self.id)),
            self.as_desktop_file(exec),
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
