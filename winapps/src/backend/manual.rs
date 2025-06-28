use std::{net::IpAddr, str::FromStr};

use crate::{command::Command, ensure, Backend, Config, Error, Result};

#[derive(Debug)]
pub struct Manual {
    config: &'static Config,
}

impl Manual {
    pub(crate) fn new(config: &'static Config) -> Self {
        Self { config }
    }
}

impl Backend for Manual {
    fn check_depends(&self) -> Result<()> {
        assert!(self.config.manual.enable);
        ensure!(
            !self.config.manual.host.is_empty(),
            Error::Config("Host shouldn't be empty")
        );

        ensure!(
            IpAddr::from_str(&self.config.manual.host).is_ok(),
            Error::Config("manual.host is not a valid IP address")
        );

        Ok(())
    }

    fn get_host(&self) -> IpAddr {
        IpAddr::from_str(&self.config.manual.host).unwrap()
    }

    fn get_remote_command(&self, command: Command) -> Command {
        Command::new("sshpass")
            .args(["-p", &*self.config.auth.password])
            .args([
                "ssh",
                &*format!("{}@{}", self.config.auth.username, self.config.manual.host),
                "-p",
                &*self.config.auth.ssh_port.to_string(),
            ])
            .arg(format!("{} {}", command.exec, command.args.join(" ")))
    }
}
