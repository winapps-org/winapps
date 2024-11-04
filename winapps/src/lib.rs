#![feature(decl_macro)]
#![feature(exit_status_error)]

mod backend;
mod command;
mod errors;
mod remote_client;

pub mod config;

pub use crate::backend::Backend;
pub use crate::config::Config;
pub use crate::errors::{bail, ensure, Error, IntoResult, Result};
pub use crate::remote_client::{freerdp::Freerdp, RemoteClient};
