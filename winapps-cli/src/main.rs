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
        .subcommand(
            Command::new("run")
                .about("Runs a configured app or an executable on the remote")
                .arg(arg!(NAME: "the name of the app/the path to the executable")),
        )
}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        // .with_timer(tracing_subscriber::fmt::time::uptime())
        .without_time()
        .with_target(false)
        .with_level(true)
        .with_max_level(Level::INFO)
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    let cli = cli();
    let matches = cli.clone().get_matches();

    let config = Config::load()?;

    let client = Freerdp::new(config);
    let backend = config.get_backend();

    client.check_depends()?;
    backend.check_depends()?;

    match matches.subcommand() {
        Some(("connect", _)) => {
            info!("Connecting to remote");

            client.run_full_session()?;
            Ok(())
        }

        Some(("run", sub_matches)) => {
            info!("Connecting to app on remote");

            match sub_matches.get_one::<String>("name") {
                None => panic!("App is required and should never be None here"),
                Some(app) => client.run_app(app),
            }?;

            Ok(())
        }

        _ => cli
            .about("Command not found, try existing ones!")
            .print_help()
            .into_diagnostic(),
    }
}
