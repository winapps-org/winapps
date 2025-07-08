use std::{
    net::{SocketAddr, TcpStream},
    time::Duration,
};
use tracing::info;

use crate::{command::Command, config::App, Config, Error, RemoteClient, Result};

pub struct Freerdp {
    config: &'static Config,
}

impl Freerdp {
    const TIMEOUT: Duration = Duration::from_secs(5);
    const RDP_PORT: u16 = 3389;

    fn get_command(&self) -> Command {
        Command::new(self.config.freerdp.executable.as_str())
            .with_err("Freerdp execution failed, check logs above!")
            .args(vec![
                format!("/d:{}", &self.config.auth.domain),
                format!("/u:{}", &self.config.auth.username),
                format!("/p:{}", &self.config.auth.password),
                format!("/v:{}", &self.config.get_host()),
            ])
            .args(self.config.freerdp.extra_args.iter().cloned())
            .loud(self.config.debug)
    }

    pub fn new(config: &'static Config) -> Self {
        Self { config }
    }
}

impl RemoteClient for Freerdp {
    fn check_depends(&self) -> Result<()> {
        self.get_command()
            .clear_args()
            .with_err("Freerdp execution failed, is `freerdp.executable` correctly set, FreeRDP properly installed and the binary on $PATH?")
            .spawn()?;

        info!("Freerdp found!");
        info!("Checking whether host is reachable..");

        let socket_address = SocketAddr::new(self.config.get_host(), Self::RDP_PORT);

        TcpStream::connect_timeout(&socket_address, Self::TIMEOUT)
            .map(|_| ())
            .map_err(|_| Error::HostUnreachable)?;

        Ok(())
    }

    fn run_app(&self, app_name: &str) -> Result<()> {
        let path = self
            .config
            .linked_apps
            .iter()
            .filter_map(|app| app.id.eq(app_name).then_some(app.win_exec.clone()))
            .next()
            .unwrap_or(app_name.to_string());

        self.get_command()
            .arg(format!("/app:program:{path}"))
            .spawn()
            .map(|_| ())
    }

    fn run_full_session(&self) -> Result<()> {
        self.get_command()
            .arg("+dynamic-resolution".to_string())
            .spawn()
            .map(|_| ())
    }
}
