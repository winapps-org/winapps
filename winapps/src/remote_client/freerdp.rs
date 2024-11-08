use std::process::{Command, Stdio};
use std::sync::RwLockReadGuard;

use tracing::{info, warn};

use crate::{command::execute, Backend, Config, RemoteClient, Result};

pub struct Freerdp {
    config: RwLockReadGuard<'static, Config>,
}

impl Freerdp {
    pub fn new() -> Self {
        Self {
            config: Config::get(),
        }
    }

    fn get_command(&self) -> Command {
        let mut command = Command::new("xfreerdp");

        command.stdout(Stdio::null()).stderr(Stdio::null()).args([
            &format!("/d:{}", &self.config.auth.domain),
            &format!("/u:{}", &self.config.auth.username),
            &format!("/p:{}", &self.config.auth.password),
            &format!("/v:{}", &self.config.get_backend().get_host()),
            "/dynamic-resolution",
            "+auto-reconnect",
            "+clipboard",
            "+home-drive",
        ]);

        command
    }
}

impl Default for Freerdp {
    fn default() -> Self {
        Self::new()
    }
}

impl RemoteClient for Freerdp {
    fn check_depends(&self) -> Result<()> {
        let mut xfreerdp = self.get_command();
        xfreerdp.arg("-h");

        execute(xfreerdp, "Freerdp execution failed, check logs above!")?;

        info!("Freerdp found!");

        info!("All dependencies found!");
        info!("Running explorer as test!");
        warn!("Check yourself if it appears correctly!");

        self.run_executable("explorer.exe".to_string())?;

        info!("Test finished!");

        Ok(())
    }

    fn run_executable(&self, app: String) -> Result<()> {
        let mut xfreerdp = self.get_command();
        xfreerdp.arg(format!("/app:{app}"));

        execute(xfreerdp, "Freerdp execution failed, check logs above!").map(|_| ())
    }

    fn run_windows(&self) -> Result<()> {
        execute(
            self.get_command(),
            "Freerdp execution failed, check logs above!",
        )
        .map(|_| ())
    }
}
