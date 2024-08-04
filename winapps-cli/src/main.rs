use clap::{arg, Command};
use tracing::info;
use winapps::freerdp::freerdp_back::Freerdp;
use winapps::{unwrap_or_panic, RemoteClient};

fn cli() -> Command {
    Command::new("winapps-cli")
        .about("The winapps-cli is a command line interface for winapps")
        .subcommand_required(true)
        .arg_required_else_help(true)
        .allow_external_subcommands(true)
        .subcommand(Command::new("check").about("Checks remote connection"))
        .subcommand(Command::new("connect").about("Connects to remote"))
        .subcommand(
            Command::new("run")
                .about("Connects to app on remote")
                .arg(arg!(<APP> "App to open")),
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

    let client: &dyn RemoteClient = &Freerdp {};
    let config = winapps::load_config(None);

    match matches.subcommand() {
        Some(("check", _)) => {
            info!("Checking remote connection");

            client.check_depends(config);
        }
        Some(("connect", _)) => {
            info!("Connecting to remote");

            client.run_app(config, None);
        }
        Some(("run", sub_matches)) => {
            info!("Connecting to app on remote");

            client.run_app(config, sub_matches.get_one::<String>("APP"));
        }
        Some((_, _)) => {
            unwrap_or_panic!(
                cli.about("Command not found, try existing ones!")
                    .print_help(),
                "Couldn't print help"
            );
        }
        _ => unreachable!(),
    }
}
