use std::{
    net::{SocketAddr, TcpStream},
    time::Duration,
};
use tracing::info;

use crate::{command::Command, Config, Error, RemoteClient, Result};

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

    fn run_executable(&self, app: String) -> Result<()> {
        self.get_command()
            .arg(format!("/app:program:{app}"))
            .spawn()
            .map(|_| ())
    }

    fn run_windows(&self) -> Result<()> {
        self.get_command().spawn().map(|_| ())
    }
}
