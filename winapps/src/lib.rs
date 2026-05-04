#![allow(clippy::new_without_default)]
#![warn(clippy::unwrap_used)]
#![feature(decl_macro)]
#![feature(exit_status_error)]
#![feature(string_from_utf8_lossy_owned)]

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
