use clap::{arg, Command};
use winapps::freerdp::freerdp_back::Freerdp;
use winapps::quickemu::{create_vm, kill_vm, start_vm};
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
}

fn main() {
    let cli = cli();
    let matches = cli.clone().get_matches();

    let client: &dyn RemoteClient = &Freerdp {};
    let config = winapps::load_config(None);

    match matches.subcommand() {
        Some(("check", _)) => {
            println!("Checking remote connection");

            client.check_depends(config);
        }
        Some(("connect", _)) => {
            println!("Connecting to remote");

            client.run_app(config, None);
        }
        Some(("run", sub_matches)) => {
            println!("Connecting to app on remote");

            client.run_app(config, sub_matches.get_one::<String>("APP"));
        }

        Some(("vm", command)) => {
            match command.subcommand() {
                Some(("create", _)) => {
                    println!("Creating windows 10 vm..");
                    create_vm(config);
                }
                Some(("start", _)) => {
                    println!("Starting vm..");
                    start_vm(config);
                }

                Some(("kill", _)) => {
                    println!("Killing vm..");
                    kill_vm(config);
                }

                Some((_, _)) => {
                    unwrap_or_panic!(
                        cli.about("Command not found, try existing ones!")
                            .print_help(),
                        "Couldn't print help"
                    );
                }
                _ => unreachable!(),
            };
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
