use crate::{Config, Error, IntoResult, Result, bail, ensure};
use shlex::split;
use std::{
    fmt::{Display, Formatter},
    iter,
    process::{Child, Command as StdCommand, Stdio},
    str::FromStr,
};
use tracing::debug;

pub struct Command {
    pub exec: String,
    pub args: Vec<String>,
    error_message: String,
    loud: bool,
}

impl Display for Command {
    fn fmt(&self, f: &mut Formatter) -> std::fmt::Result {
        f.write_str(self.exec.as_str())?;
        f.write_str(" ")?;
        f.write_str(self.args.join(" ").as_str())
    }
}

impl FromStr for Command {
    type Err = Error;

    fn from_str(command: &str) -> std::result::Result<Self, Self::Err> {
        ensure!(!command.is_empty(), Error::EmptyCommand);

        let mut items = split(command).unwrap_or_default().into_iter();

        let Some(exec) = items.next() else {
            bail!("Commands should have an executable")
        };

        Ok(Command::new(exec).args(items))
    }
}

impl Command {
    pub fn new<T: Into<String> + Display>(exec: T) -> Self {
        Self {
            error_message: format!("Error running child command {}", &exec),
            exec: exec.into(),
            args: Vec::new(),
            loud: false,
        }
    }

    pub fn into_remote(mut self, config: &Config) -> Self {
        let prev = iter::once(self.exec)
            .chain(self.args.iter().cloned())
            .collect::<Vec<String>>()
            .join(" ");

        self.exec = "sshpass".to_string();
        self.clear_args()
            .args(["-p", config.auth.password.as_str()])
            .args([
                "ssh",
                format!("{}@{}", config.auth.username, config.get_host()).as_str(),
                "-oStrictHostKeyChecking=accept-new",
                "-oWarnWeakCrypto=no-pq-kex",
                "-p",
                config.auth.ssh_port.to_string().as_str(),
            ])
            .arg(prev)
    }

    pub fn with_err(mut self, message: &'static str) -> Self {
        self.error_message = message.to_string();
        self
    }

    pub fn loud(mut self, loud: bool) -> Self {
        self.loud = loud;
        self
    }

    pub fn arg<S>(mut self, arg: S) -> Self
    where
        S: ToString,
    {
        self.args.push(arg.to_string());

        self
    }

    pub fn args<I, S>(mut self, args: I) -> Self
    where
        I: IntoIterator<Item = S>,
        S: ToString,
    {
        let mut args = args
            .into_iter()
            .map(|s| s.to_string())
            .collect::<Vec<String>>();

        self.args.append(&mut args);

        self
    }

    pub fn clear_args(mut self) -> Self {
        self.args = Vec::new();

        self
    }

    pub fn spawn(&self) -> Result<Child> {
        debug!("Running {self}");

        let mut command = StdCommand::new(&self.exec);

        if !self.loud {
            command.stdout(Stdio::piped()).stderr(Stdio::piped());
        }

        command.args(&self.args);

        command.spawn().map_err(|source| Error::Command {
            source: source.into(),
            message: self.error_message.clone(),
        })
    }

    pub fn wait_with_output(&self) -> Result<String> {
        let output = self.spawn()?.wait_with_output().into_result()?;

        output.status.exit_ok().map_err(|source| Error::Command {
            source: source.into(),
            message: self.error_message.clone(),
        })?;

        let stdout = String::from_utf8_lossy_owned(output.stdout);

        debug!("Got stdout: {stdout}");
        debug!(
            "Got stderr: {}",
            String::from_utf8_lossy_owned(output.stderr)
        );

        Ok(stdout)
    }
}

pub macro command($($fmt:tt)*) {
    $crate::command::Command::from_str(&format!($($fmt)*))
}
