use std::fmt::Debug;

use miette::Diagnostic;

/// This enum represents all possible errors that can occur in this crate.
///
/// It is used as a return type for most functions should they return an error.
/// There are multiple variants:
/// `Message` is used for simple errors that don't have an underlying cause.
/// `IoError` is used for errors that occur from an `std::io::Error`.
#[derive(thiserror::Error, Diagnostic, Debug)]
pub enum Error {
    #[error("{0}")]
    #[diagnostic(code(winapps::error))]
    Message(String),

    #[error("invalid config: {0}")]
    #[diagnostic(code(winapps::bad_config_error))]
    Config(&'static str),

    #[error(transparent)]
    #[diagnostic(code(winapps::io_error))]
    Io(#[from] std::io::Error),

    #[error("{message}")]
    #[diagnostic(code(winapps::child_command_error))]
    Command {
        message: String,
        source: anyhow::Error,
    },

    #[error("VM or container not running")]
    #[diagnostic(
        code(winapps::bad_vm_state),
        help("Ensure your VM or container is started")
    )]
    VmNotRunning,

    #[error(transparent)]
    #[diagnostic(code(winapps::toml_invalid_error))]
    Deserialize(#[from] toml::de::Error),

    #[error(transparent)]
    #[diagnostic(code(winapps::toml_invalid_error))]
    Serialize(#[from] toml::ser::Error),

    #[error("Icon is invalid base64")]
    #[diagnostic(
        code(winapps::setup_error),
        help(
            "Setup returned a badly formed base64 string, is your config correct and are apps correctly installed?"
        )
    )]
    InvalidIcon(#[from] base64::DecodeError),

    #[error("RDP host is unreachable")]
    #[diagnostic(
        code(winapps::bad_vm_state),
        help(
            "Ensure that the VM or your Firewall doesn't block ping traffic. \
        In case you're running a containerized VM, ensure the container runtime is properly configured."
        )
    )]
    HostUnreachable,

    #[error("String passed to Command::fromStr was empty")]
    #[diagnostic(code(winapps::bad_string_command))]
    EmptyCommand,
}

impl From<&str> for Error {
    fn from(value: &str) -> Self {
        Self::Message(value.to_string())
    }
}

pub type Result<T> = std::result::Result<T, Error>;

impl<T> From<Error> for Result<T> {
    fn from(value: Error) -> Self {
        Err(value)
    }
}

pub trait IntoResult<T> {
    fn into_result(self) -> Result<T>;
}

impl<T, E> IntoResult<T> for std::result::Result<T, E>
where
    Error: From<E>,
{
    fn into_result(self) -> Result<T> {
        self.map_err(|e| Error::from(e))
    }
}

impl<T> IntoResult<T> for &str {
    fn into_result(self) -> Result<T> {
        Err(Error::Message(self.to_string()))
    }
}

/// Return early if a condition isn't met, calling `bail!` with the second argument
/// Basically like an assertion which doesn't panic
pub macro ensure {
    ($cond:expr, $err:expr) => {
        if !$cond {
            $crate::bail!($err);
        }
    },
    ($cond:expr, $err:expr, $($fmt:tt)*) => {
        if !$cond {
            $crate::bail!($err, $($fmt)*)
        }
    }
}

/// Return, converting the argument into an error
/// Supports `format!` syntax
pub macro bail {
    ($err:expr) => {
        return Err($err.into())
    },
    ($err:expr, $($fmt:tt)*) => {
        return Err($crate::Error::Message(format!($err, $($fmt)*)))
    }
}
