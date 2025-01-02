use crate::{ensure, Error, IntoResult, Result};
use std::{
    fmt::{Display, Formatter},
    process::{Child, Command as StdCommand, Stdio},
    str::FromStr,
};
use tracing::debug;

pub struct Command {
    exec: String,
    args: Vec<String>,
    error_message: String,
    loud: bool,
}

impl Display for Command {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.exec.as_str())?;
        f.write_str(self.args.join(" ").as_str())
    }
}

impl FromStr for Command {
    type Err = Error;

    fn from_str(command: &str) -> std::result::Result<Self, Self::Err> {
        ensure!(!command.is_empty(), Error::EmptyCommand);

        let (exec, args) = if command.contains(" ") {
            let mut split = command.split(" ");

            (
                split
                    .next()
                    .expect("There should always be at least one element in the split if the command contains a space")
                    .to_string(),
                split.map(|s| s.to_string()).collect::<Vec<String>>(),
            )
        } else {
            (command.to_string(), Vec::new())
        };

        Ok(Self {
            exec,
            args,
            error_message: String::from("Error running child command"),
            loud: false,
        })
    }
}

impl Command {
    pub fn new(exec: &'static str) -> Self {
        Self {
            exec: exec.to_string(),
            args: Vec::new(),
            error_message: String::from("Error running child command"),
            loud: false,
        }
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

        Ok(format!(
            "{}\n{}",
            String::from_utf8(output.stdout).expect("Commands should always return valid utf-8"),
            String::from_utf8(output.stderr).expect("Commands should always return valid utf-8")
        ))
    }
}

pub macro command($($fmt:tt)*) {
    $crate::command::Command::from_str(&format!($($fmt)*))
}
