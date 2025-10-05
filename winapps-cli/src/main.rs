use clap::{arg, Command};
use miette::{IntoDiagnostic, Result};
use tracing::{info, Level};
use tracing_subscriber::EnvFilter;
use winapps::{Backend, Config, Freerdp, RemoteClient};

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
        .without_time()
        .with_target(false)
        .with_level(true)
        .with_max_level(Level::INFO)
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    let config_lock = Config::try_get_lock()?;
    config_lock.read().get_backend().check_depends()?;

    let cli = cli();

    match cli.clone().get_matches().subcommand() {
        Some(("setup", _)) => {
            info!("Running setup");

            let apps = config_lock.read().get_available_apps()?;

            // TODO: Allow deleting apps, maybe pass installed apps
            // so they can be deselected?
            match inquire::MultiSelect::new("Select apps to link", apps)
                .prompt_skippable()
                .map_err(|e| winapps::Error::Command {
                    message: "Failed to display selection dialog".into(),
                    source: e.into(),
                })? {
                Some(apps) => apps
                    .into_iter()
                    .try_for_each(|app| app.link(&mut config_lock.write()))?,
                None => info!("No apps selected, skipping setup..."),
            };

            Ok(())
        }

        Some(("connect", _)) => {
            info!("Connecting to remote");

            let client = Freerdp::new();

            client.check_depends()?;
            client.run_full_session()?;
            Ok(())
        }

        Some(("run", sub_matches)) => {
            info!("Connecting to app on remote");

            let client = Freerdp::new();

            client.check_depends()?;

            let args = sub_matches
                .get_many::<String>("ARGS")
                .map_or(Vec::new(), |args| args.map(|v| v.to_owned()).collect());

            match sub_matches.get_one::<String>("NAME") {
                None => panic!("App is required and should never be None here"),
                Some(app) => client.run_app(app.to_owned(), args),
            }?;

            Ok(())
        }

        _ => cli
            .about("Command not found, try existing ones!")
            .print_help()
            .into_diagnostic(),
    }
}
