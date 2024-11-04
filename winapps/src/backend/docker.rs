use crate::command::execute_str;
use crate::{ensure, Backend, Config, Error, Result};
use std::sync::RwLockReadGuard;

pub struct Docker {
    config: RwLockReadGuard<'static, Config>,
}

impl Docker {
    const STATE_OK: &'static str = "ok";

    pub fn new() -> Self {
        Self {
            config: Config::get(),
        }
    }
}

impl Backend for Docker {
    fn check_depends(&self) -> Result<()> {
        assert!(self.config.container.enable);
        assert!(!self.config.container.enable_podman);

        ensure!(
            !self.config.container.container_name.is_empty(),
            Error::Config("Container name shouldn't be empty")
        );

        let cmd = format!(
            r#"docker ps --all --filter name="{}" --format '{{{{.Status}}}}'"#,
            self.config.container.container_name
        );

        let output = execute_str(cmd.as_str(), "Could not get container status")?.to_lowercase();
        let state = output.split(" ").next().expect(
            "docker CLI should always return a string with at least one word split by a space",
        );

        ensure!(state == Self::STATE_OK, Error::VmNotRunning);

        Ok(())
    }

    fn get_host(&self) -> String {
        "127.0.0.1".to_string()
    }
}
