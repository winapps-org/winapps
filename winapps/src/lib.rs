#![allow(clippy::new_without_default)]
#![feature(decl_macro)]
#![feature(exit_status_error)]
#![feature(once_cell_try)]

pub use crate::{
    backend::{Backend, Backends},
    config::Config,
    errors::{Error, IntoResult, Result, bail, ensure},
    remote_client::{RemoteClient, freerdp::Freerdp},
};

mod backend;
mod command;
mod errors;
mod remote_client;

pub mod config;
mod dirs;
