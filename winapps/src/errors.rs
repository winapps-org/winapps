use std::error::Error;
use std::fmt::Debug;
use std::process::exit;

/// This enum represents all possible errors that can occur in this crate.
/// It is used as a return type for most functions should they return an error.
/// There's 2 base variants: `Message` and `WithError`.
/// `Message` is used for simple errors that don't have an underlying cause.
/// `WithError` is used for errors that occur from another error.
#[derive(thiserror::Error, Debug)]
pub enum WinappsError {
    #[error("{0}")]
    Message(String),
    #[error("{0}\n{1}")]
    WithError(#[source] anyhow::Error, String),
}

impl WinappsError {
    /// This function prints the error to the console.
    /// It is used internally by the `unrecoverable` and `panic` functions.
    /// All lines are logged as seperate messages, and the source of the error is also logged if it exists.
    fn error(&self) {
        let messages: Vec<String> = self.to_string().split('\n').map(|s| s.into()).collect();
        messages.iter().for_each(|s| tracing::error!("{}", s));

        if self.source().is_some() {
            tracing::error!("Caused by: {}", self.source().unwrap());
        }
    }

    /// This function prints the error to the console and exits the program with an exit code of 1.
    pub fn exit(&self) -> ! {
        self.error();

        tracing::error!("Unrecoverable error, exiting...");
        exit(1);
    }

    /// This function prints the error to the console and panics.
    pub fn panic(&self) -> ! {
        self.error();

        panic!("Program crashed, see log above");
    }
}

/// This macro is a shortcut for creating a `WinappsError` from a string.
/// You can use normal `format!` syntax inside the macro.
#[macro_export]
macro_rules! error {
    ($($fmt:tt)*) => {
       $crate::errors::WinappsError::Message(format!($($fmt)*))
    };
}

/// This macro is a shortcut for creating a `WinappsError` from a string.
/// The first argument is the source error.
/// You can use normal `format!` syntax inside the macro.
#[macro_export]
macro_rules! error_from {
    ($err:expr, $($fmt:tt)*) => {
       $crate::errors::WinappsError::WithError(anyhow::Error::new($err), format!($($fmt)*))
    };
}

/// This trait serves as a generic way to convert a `Result` or `Option` into a `WinappsError`.
pub trait IntoError<T> {
    fn into_error(self, msg: String) -> Result<T, WinappsError>;
}

impl<T, U> IntoError<T> for Result<T, U>
where
    T: Debug,
    U: Error + Send + Sync + 'static,
{
    fn into_error(self, msg: String) -> Result<T, WinappsError> {
        if let Err(error) = self {
            return Err(WinappsError::WithError(anyhow::Error::new(error), msg));
        }

        Ok(self.unwrap())
    }
}

impl<T> IntoError<T> for Option<T> {
    fn into_error(self, msg: String) -> Result<T, WinappsError> {
        if self.is_none() {
            return Err(WinappsError::Message(msg));
        }

        Ok(self.unwrap())
    }
}

/// This function unwraps a `Result` or `Option` and returns the value if it exists.
/// Should the value not exist, then the program will exit with an exit code of 1.
/// Called internally by the `unwrap_or_exit!` macro, which you should probably use instead.
pub fn unwrap_or_exit<T, U>(val: U, msg: String) -> T
where
    T: Sized + Debug,
    U: IntoError<T>,
{
    val.into_error(msg).unwrap_or_else(|e| e.exit())
}

/// This function unwraps a `Result` or `Option` and returns the value if it exists.
/// Should the value not exist, then the program will panic.
/// Called internally by the `unwrap_or_panic!` macro, which you should probably use instead.
pub fn unwrap_or_panic<T, U>(val: U, msg: String) -> T
where
    T: Sized + Debug,
    U: IntoError<T>,
{
    val.into_error(msg).unwrap_or_else(|e| e.panic())
}

/// This macro unwraps a `Result` or `Option` and returns the value if it exists.
/// Should the value not exist, then the program will exit with exit code 1.
/// Optionally, a message can be passed to the function which uses standard `format!` syntax.
/// The result type has to implement `Debug` and `Sized`, and the error type has to implement `Error`, `Send`, `Sync` has to be `'static`.
#[macro_export]
macro_rules! unwrap_or_exit {
    ($expr:expr) => {{
        $crate::errors::unwrap_or_exit($expr, "Expected a value, got None / Error".into())
    }};
    ($expr:expr, $($fmt:tt)*) => {{
        $crate::errors::unwrap_or_exit($expr, format!($($fmt)*))
    }};
}

/// This macro unwraps a `Result` or `Option` and returns the value if it exists.
/// Should the value not exist, then the program will panic.
/// Optionally, a message can be passed to the function which uses standard `format!` syntax.
/// The result type has to implement `Debug` and `Sized`, and the error type has to implement `Error`, `Send`, `Sync` has to be `'static`.
#[macro_export]
macro_rules! unwrap_or_panic {
    ($expr:expr) => {{
        $crate::errors::unwrap_or_panic($expr, "Expected a value, got None / Error".into())
    }};
    ($expr:expr, $($fmt:tt)*) => {{
        $crate::errors::unwrap_or_panic($expr, format!($($fmt)*))
    }};
}
