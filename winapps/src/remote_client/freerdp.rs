use crate::{bail, command::Command, Config, Error, RemoteClient, Result};
use regex::Regex;
use std::{
    net::{SocketAddr, TcpStream},
    time::Duration,
};
use tracing::info;

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

    fn run_app(&self, app_name: String, args: Vec<String>) -> Result<()> {
        let path = self
            .config
            .linked_apps
            .iter()
            .filter_map(|app| app.id.eq(&app_name).then_some(app.win_exec.clone()))
            .next()
            .unwrap_or(app_name);

        let Some(home_regex) = dirs::home_dir().map(|home| {
            Regex::new(&format!(
                "^{}",
                home.into_os_string()
                    .into_string()
                    .expect("$HOME should always be a valid string")
            ))
            .expect("'^$HOME' should always be a valid regex")
        }) else {
            bail!("Couldn't find $HOME")
        };

        self.get_command()
            .arg(format!("/app:program:{path}"))
            .args(args.iter().map(|arg| {
                if arg.contains("/") && home_regex.is_match(arg) {
                    home_regex
                        .replace(arg, r"\\tsclient\\media")
                        .to_string()
                        .replace("/", r"\")
                } else {
                    arg.to_owned()
                }
            }))
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
