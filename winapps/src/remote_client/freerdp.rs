use crate::{Config, Error, RemoteClient, Result, bail, command::Command};
use parking_lot::RwLock;
use regex::Regex;
use std::{
    net::{SocketAddr, TcpStream},
    time::Duration,
};
use tracing::info;

pub struct Freerdp {
    config: &'static RwLock<Config>,
}

impl Freerdp {
    const TIMEOUT: Duration = Duration::from_secs(5);
    const RDP_PORT: u16 = 3389;

    fn get_command(&self) -> Command {
        let config = self.config.read();

        Command::new(config.freerdp.executable.to_owned())
            .with_err("Freerdp execution failed, check logs above!")
            .args(vec![
                format!("/d:{}", &config.auth.domain),
                format!("/u:{}", &config.auth.username),
                format!("/p:{}", &config.auth.password),
                format!("/v:{}", &config.get_host()),
            ])
            .args(config.freerdp.extra_args.iter().cloned())
            .loud(config.debug)
    }

    pub fn new() -> Self {
        Self {
            config: Config::get_lock(),
        }
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

        let socket_address = SocketAddr::new(self.config.read().get_host(), Self::RDP_PORT);

        TcpStream::connect_timeout(&socket_address, Self::TIMEOUT)
            .map(|_| ())
            .map_err(|_| Error::HostUnreachable)?;

        Ok(())
    }

    fn run_app(&self, app_name: String, args: Vec<String>) -> Result<()> {
        let path = self
            .config
            .read()
            .linked_apps
            .iter()
            .filter_map(|app| app.id.eq(&app_name).then_some(app.win_exec.clone()))
            .next()
            .unwrap_or(app_name);

        let Some(home_regex) = dirs::home_dir().map(|home| {
            Regex::new(&format!(
                "^{}",
                regex::escape(
                    home.as_os_str()
                        .to_str()
                        .expect("$HOME should always be valid UTF-8")
                )
            ))
            .expect("'^$HOME' should always be a valid regex")
        }) else {
            bail!("Couldn't find $HOME")
        };

        self.get_command()
            .arg(format!("/app:program:{path},hidef:on"))
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
