use crate::{Backend, Config, Error, Result, command::command, ensure};
use parking_lot::RwLock;
use std::net::{IpAddr, Ipv4Addr};
use tracing::debug;

#[derive(Debug, Clone)]
pub struct Container {
    config: &'static RwLock<Config>,
}

impl Container {
    const STATE_RUNNING: &'static str = "running";

    const DEFAULT_COMMAND: &'static str = "docker";
    const PODMAN_COMMAND: &'static str = "podman";

    pub(crate) fn new() -> Self {
        Self {
            config: Config::get_lock(),
        }
    }
}

impl Backend for Container {
    fn check_depends(&self) -> Result<()> {
        let config = self.config.read();
        assert!(config.container.enable);

        ensure!(
            !config.container.container_name.is_empty(),
            Error::Config("Container name shouldn't be empty")
        );

        let command = if config.container.enable_podman {
            Self::PODMAN_COMMAND
        } else {
            Self::DEFAULT_COMMAND
        };

        let state = command!(
            r#"{command} ps --all --filter name={} --format {{{{.State}}}}"#,
            config.container.container_name
        )?
        .with_err("Could not get container status")
        .wait_with_output()?;

        debug!("{command} returned state: {state}");
        ensure!(state.trim() == Self::STATE_RUNNING, Error::VmNotRunning);

        Ok(())
    }

    fn get_host(&self) -> IpAddr {
        Ipv4Addr::new(127, 0, 0, 1).into()
    }
}
