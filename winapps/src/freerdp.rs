pub mod freerdp_back {
    use std::process::{Command, Stdio};

    use crate::{RemoteClient, Config};

    pub struct Freerdp {}

    impl RemoteClient for Freerdp {
        fn check_depends(&self, _config: Config) {

            let mut xfreerdp = Command::new("xfreerdp");
            xfreerdp.stdout(Stdio::null());
            xfreerdp.args(["-h"]);
            xfreerdp.spawn().expect("Freerdp execution failed! It needs to be installed!");
            println!("Freerdp found!");
            
            println!("Checks success!");
        }

        fn run_app(&self, config: Config, _app: &str) {
            todo!()
        }
    }
}
