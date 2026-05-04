use std::collections::HashSet;

use clap::{Command, arg};
use inquire::MultiSelect;
use miette::{IntoDiagnostic, Result};
use tracing::{Level, debug, info};
use tracing_subscriber::EnvFilter;
use winapps::{Config, Freerdp, RemoteClient, config::App};

fn cli() -> Command {
    Command::new("winapps-cli")
        .about("The winapps-cli is a command line interface for winapps")
        .subcommand_required(true)
        .arg_required_else_help(true)
        .allow_external_subcommands(true)
        .subcommand(Command::new("connect").about("Opens full session on remote"))
        .subcommand(Command::new("setup").about("Create desktop files for installed Windows apps"))
        .subcommand(
            Command::new("run")
                .about("Runs a configured app or an executable on the remote")
                .arg(arg!(<NAME> "the name of the app/the path to the executable"))
                .arg(
                    arg!([ARGS]... "Arguments to pass to the command")
                        .trailing_var_arg(true)
                        .allow_hyphen_values(true),
                ),
        )
}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_level(true)
        .with_max_level(Level::INFO)
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    let mut config = Config::try_new()?;
    let client = Freerdp;

    config.backend_check_depends()?;
    client.check_depends(&config)?;

    let cli = cli();

    match cli.clone().get_matches().subcommand() {
        Some(("setup", _)) => {
            info!("Running setup");

            let available = config.get_available_apps()?;
            let installed: Vec<usize> = available
                .iter()
                .enumerate()
                .filter_map(|(i, app)| config.linked_apps.contains_key(&app.id).then_some(i))
                .collect();

            debug!(
                "{} apps available, {} apps installed",
                available.len(),
                config.linked_apps.len()
            );

            match MultiSelect::new("Select apps to link", available)
                .with_default(installed.as_slice())
                .with_page_size(20)
                .prompt_skippable()
                .map_err(|e| winapps::Error::Command {
                    message: "Failed to display selection dialog".into(),
                    source: e.into(),
                })? {
                Some(apps) => {
                    let selected: HashSet<App> = apps.into_iter().collect();
                    let installed: HashSet<App> = config.linked_apps.values().cloned().collect();

                    for app in selected.symmetric_difference(&installed).cloned() {
                        match (selected.contains(&app), installed.contains(&app)) {
                            (true, false) => app.link(&mut config)?,
                            (false, true) => app.unlink(&mut config)?,
                            (false, false) => (),
                            (true, true) => unreachable!(),
                        }
                    }
                }
                None => info!("No apps (de-)selected, skipping setup..."),
            };

            Ok(())
        }

        Some(("connect", _)) => {
            info!("Connecting to remote");

            client.run_full_session(&config)?;
            Ok(())
        }

        Some(("run", sub_matches)) => {
            info!("Connecting to app on remote");

            let args = sub_matches
                .get_many::<String>("ARGS")
                .map_or(Vec::new(), |args| args.map(|v| v.to_owned()).collect());

            match sub_matches.get_one::<String>("NAME") {
                None => unreachable!("App is required and should never be None here"),
                Some(app) => client.run_app(&config, app.to_owned(), args),
            }?;

            Ok(())
        }

        _ => cli
            .about("Command not found, try existing ones!")
            .print_help()
            .into_diagnostic(),
    }
}
