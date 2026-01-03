use crate::{Backend, Config, Error, Result, command::command, ensure};
use std::net::{IpAddr, Ipv4Addr};
use tracing::debug;

#[derive(Debug, Clone, Copy)]
pub struct Container;

impl Container {
    const STATE_RUNNING: &'static str = "running";

    const DEFAULT_COMMAND: &'static str = "docker";
    const PODMAN_COMMAND: &'static str = "podman";
}

impl Backend for Container {
    fn check_depends(self, config: &Config) -> Result<()> {
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

    fn get_host(self, _config: &Config) -> IpAddr {
        Ipv4Addr::LOCALHOST.into()
    }
}
