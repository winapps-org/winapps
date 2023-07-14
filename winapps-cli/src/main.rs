use clap::Command;

fn cli() -> Command {
    Command::new("winapps-cli")
        .about("The winapps-cli is a command line interface for winapps")
        .subcommand_required(true)
        .arg_required_else_help(true)
        .allow_external_subcommands(true)
        .subcommand(Command::new("check").about("Checks remote connection"))
        .subcommand(Command::new("connect").about("Connects to remote"))
}

fn main() {
    let cli = cli();
    let matches = cli.clone().get_matches();

    match matches.subcommand() {
        Some(("check", _)) => {
            println!("Checking remote connection");

            let _config = winapps::load_config(None);
        }
        Some(("connect", _)) => {
            println!("Connecting to remote");
        }
        Some((_, _)) => {
            cli.about("Command not found try existing ones!")
                .print_help();
        }
        _ => unreachable!(),
    }
}
