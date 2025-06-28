use crate::{config::App, Result};

pub(crate) mod freerdp;

pub trait RemoteClient {
    fn check_depends(&self) -> Result<()>;

    fn run_app(&self, exec: &str) -> Result<()>;

    fn run_full_session(&self) -> Result<()>;

    fn get_installed_apps(&self) -> Result<Vec<App>>;
}
