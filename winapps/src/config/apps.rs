use crate::{config::App, Config};

impl PartialEq for App {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl App {
    pub fn install(&self, config: &mut Config) {
        if !config.installed_apps.contains(self) {
            config.installed_apps.push(self.clone())
        }
    }
}

impl Config {
    pub fn find_app(&self, id: String) -> Option<&App> {
        self.installed_apps.iter().find(|app| app.id == id)
    }
}
