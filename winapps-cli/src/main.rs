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
        .subcommand(
            Command::new("vm")
                .about("Manage a windows 10 vm using quickemu")
                .subcommand_required(true)
                .arg_required_else_help(true)
                .allow_external_subcommands(true)
                .subcommand(Command::new("create").about("Create a windows 10 vm using quickget"))
                .subcommand(Command::new("start").about("Start the vm"))
                .subcommand(Command::new("kill").about("Kill the running VM")),
        )
        .subcommand(
            Command::new("app")
                .about("Connects to app on remote")
                .arg(arg!(<APP> "App to open")),
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

    let config = Config::load()?;

    let client = Freerdp::new(config);
    let backend = config.get_backend();

    client.check_depends()?;
    backend.check_depends()?;

    let cli = cli();

    match cli.clone().get_matches().subcommand() {
        Some(("setup", _)) => {
            info!("Running setup");
            todo!()
        }

        Some(("connect", _)) => {
            info!("Connecting to remote");

            client.run_full_session()?;
            Ok(())
        }

        Some(("run", sub_matches)) => {
            info!("Connecting to app on remote");

            let args = sub_matches
                .get_many::<String>("args")
                .map_or(Vec::new(), |args| args.map(|v| v.to_owned()).collect());

            match sub_matches.get_one::<String>("name") {
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
