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

/// This macro creates a `Result<_, WinappsError>` from either a `Result` or an `Option`.
/// It also works for all other types that implement `IntoError`.
/// Used internally by `winapps::unwrap_or_exit!` and `winapps::unwrap_or_panic!`.
#[macro_export]
macro_rules! into_error {
    ($val:expr) => {{
        fn into_error_impl<T, U>(val: U) -> std::result::Result<T, $crate::errors::WinappsError>
        where
            T: std::marker::Sized + std::fmt::Debug,
            U: $crate::errors::IntoError<T>,
        {
            val.into_error(
                "Expected a value, got None / an Error. \
                See log above for more detail."
                    .into(),
            )
        }

        into_error_impl($val)
    }};
    ($val:expr, $msg:expr) => {{
        fn into_error_impl<T, U>(
            val: U,
            msg: String,
        ) -> std::result::Result<T, $crate::errors::WinappsError>
        where
            T: std::marker::Sized + std::fmt::Debug,
            U: $crate::errors::IntoError<T>,
        {
            val.into_error(msg)
        }

        into_error_impl($val, $msg.into())
    }};
}

/// This macro unwraps a `Result` or `Option` and returns the value if it exists.
/// Should the value not exist, then the program will exit with exit code 1.
/// Optionally, a message can be passed to the function using standard `format!` syntax.
/// The result type has to implement `Debug` and `Sized`, and the source error type has to implement `Error`, `Send`, `Sync` and has to be `'static`.
/// See `winapps::unwrap_or_panic!` for a version that panics instead of exiting.
#[macro_export]
macro_rules! unwrap_or_exit {
    ($expr:expr) => {{
        $crate::into_error!($expr).unwrap_or_else(|e| e.exit())
    }};
    ($expr:expr, $($fmt:tt)*) => {{
        $crate::into_error!($expr, format!($($fmt)*)).unwrap_or_else(|e| e.exit())
    }};
}

/// This macro unwraps a `Result` or `Option` and returns the value if it exists.
/// Should the value not exist, then the program will panic.
/// Optionally, a message can be passed to the function using standard `format!` syntax.
/// The result type has to implement `Debug` and `Sized`, and the error type has to implement `Error`, `Send`, `Sync` and has to be `'static`.
/// See `winapps::unwrap_or_exit!` for a version that exits instead of panicking.
#[macro_export]
macro_rules! unwrap_or_panic {
    ($expr:expr) => {{
        $crate::into_error!($expr).unwrap_or_else(|e| e.panic())
    }};
    ($expr:expr, $($fmt:tt)*) => {{
        $crate::into_error!($expr, format!($($fmt)*)).unwrap_or_else(|e| e.panic())
    }};
}
