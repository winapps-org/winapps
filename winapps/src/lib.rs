#![feature(decl_macro)]
#![feature(exit_status_error)]
#![feature(once_cell_try)]

pub use crate::{
    backend::{Backend, Backends},
    config::Config,
    errors::{bail, ensure, Error, IntoResult, Result},
    remote_client::{freerdp::Freerdp, RemoteClient},
};

mod backend;
mod command;
mod errors;
mod remote_client;

pub mod config;
mod dirs;
