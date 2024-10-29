use clap::{arg, Command};
use tracing::info;
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
                .arg(arg!(<NAME> "the name of the app/the path to the executable")),
        )
}

fn main() {
    tracing_subscriber::fmt()
        // .with_timer(tracing_subscriber::fmt::time::uptime())
        .without_time()
        .with_target(false)
        .init();

    let cli = cli();
    let matches = cli.clone().get_matches();

    let config = Config::get();

    let client = Freerdp::new();
    let backend = config.get_backend();

    client.check_depends(&config);
    backend.check_depends(&config);

    match matches.subcommand() {
        Some(("connect", _)) => {
            info!("Connecting to remote");

            client.run_windows(&config);
        }
        Some(("run", sub_matches)) => {
            info!("Connecting to app on remote");

            let app = sub_matches
                .get_one::<String>("NAME")
                .expect("App is required and should never be None here");

            client.run_executable(&config, app.to_string());
        }
        Some((_, _)) => cli
            .about("Command not found, try existing ones!")
            .print_help()
            .expect("Couldn't print help"),
        _ => unreachable!(),
    }
}
