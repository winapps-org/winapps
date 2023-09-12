use clap::Command;
use winapps::freerdp::freerdp_back::Freerdp;
use winapps::quickemu::{create_vm, run_vm};
use winapps::RemoteClient;

fn cli() -> Command {
    Command::new("winapps-cli")
        .about("The winapps-cli is a command line interface for winapps")
        .subcommand_required(true)
        .arg_required_else_help(true)
        .allow_external_subcommands(true)
        .subcommand(Command::new("check").about("Checks remote connection"))
        .subcommand(Command::new("connect").about("Connects to remote"))
        .subcommand(Command::new("create-vm").about("Create a windows 10 vm using quickemu"))
        .subcommand(Command::new("run-vm").about("Start the vm using quickemu"))
}

fn main() {
    let cli = cli();
    let matches = cli.clone().get_matches();

    let client: &dyn RemoteClient = &Freerdp {};

    match matches.subcommand() {
        Some(("check", _)) => {
            println!("Checking remote connection");

            let config = winapps::load_config(None);
            client.check_depends(config);
        }
        Some(("connect", _)) => {
            println!("Connecting to remote");

            let config = winapps::load_config(None);
            client.run_app(config, "explorer");
        }
        Some(("create-vm", _)) => {
            println!("Creating windows 10 vm..");
            create_vm();
        }
        Some(("run-vm", _)) => {
            println!("Starting vm..");
            run_vm();
        }
        Some((_, _)) => {
            cli.about("Command not found, try existing ones!")
                .print_help()
                .expect("Couldn't print help");
        }
        _ => unreachable!(),
    }
}
