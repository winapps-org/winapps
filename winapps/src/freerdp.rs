pub mod freerdp_back {
    use std::process::{Command, Stdio};

    use crate::{Config, RemoteClient};

    pub struct Freerdp {}

    impl RemoteClient for Freerdp {
        fn check_depends(&self, _config: Config) {
            let mut xfreerdp = Command::new("xfreerdp");
            xfreerdp.stdout(Stdio::null());
            xfreerdp.args(["-h"]);
            xfreerdp
                .spawn()
                .expect("Freerdp execution failed! It needs to be installed!");
            println!("Freerdp found!");

            println!("All dependencies found!");
        }

        fn run_app(&self, _config: Config, _app: &str) {
            todo!()
        }
    }
}


