use crate::{command::command, ensure, Backend, Config, Error, Result};
use std::net::{IpAddr, Ipv4Addr};
use tracing::debug;

#[derive(Debug)]
pub struct Container {
    config: &'static Config,
}

impl Container {
    const STATE_RUNNING: &'static str = "running";

    const DEFAULT_COMMAND: &'static str = "docker";
    const PODMAN_COMMAND: &'static str = "podman";

    pub(crate) fn new(config: &'static Config) -> Self {
        Self { config }
    }
}

impl Backend for Container {
    fn check_depends(&self) -> Result<()> {
        assert!(self.config.container.enable);

        ensure!(
            !self.config.container.container_name.is_empty(),
            Error::Config("Container name shouldn't be empty")
        );

        let command = if self.config.container.enable_podman {
            Self::PODMAN_COMMAND
        } else {
            Self::DEFAULT_COMMAND
        };

        let state = command!(
            r#"{command} ps --all --filter name="{}" --format '{{{{.State}}}}'"#,
            self.config.container.container_name
        )?
        .with_err("Could not get container status")
        .wait_with_output()?
        .to_lowercase();

        debug!("{command} returned state: {state}");
        ensure!(state == Self::STATE_RUNNING, Error::VmNotRunning);

        Ok(())
    }

    fn get_host(&self) -> IpAddr {
        Ipv4Addr::new(127, 0, 0, 1).into()
    }
}
