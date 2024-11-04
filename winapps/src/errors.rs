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

    #[error(
        r#"
child command ran with error: {message}
command output:
{output}"#
    )]
    #[diagnostic(code(winapps::child_command_error))]
    Command {
        message: &'static str,
        output: String,
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

pub macro ensure {
    ($cond:expr, $err:expr) => {
        if $cond {
            $crate::bail!($err);
        }
    },
    ($cond:expr, $err:expr, $($fmt:tt)*) => {
        if $cond {
            $crate::bail!($err, $($fmt)*)
        }
    }
}

pub macro bail {
    ($err:expr) => {
        return Err($err.into())
    },
    ($err:expr, $($fmt:tt)*) => {
        return Err($crate::Error::Message(format!($err, $($fmt)*)))
    }
}
