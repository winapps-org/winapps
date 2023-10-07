pub mod freerdp_back {
    use std::process::{Command, Stdio};

    use crate::{Config, RemoteClient};

    pub struct Freerdp {}

    impl RemoteClient for Freerdp {
        fn check_depends(&self, config: Config) {
            let mut xfreerdp = Command::new("xfreerdp");
            xfreerdp.stdout(Stdio::null());
            xfreerdp.args(["-h"]);
            xfreerdp
                .spawn()
                .expect("Freerdp execution failed! It needs to be installed!");

            println!("Freerdp found!");

            println!("All dependencies found!");
            println!("Running explorer as test!");

            self.run_app(config, "explorer");

            println!("Test finished!");
        }

        fn run_app(&self, config: Config, _app: &str) {
            let mut xfreerdp = Command::new("xfreerdp");
            xfreerdp.args([
                //"/app:".to_owned() + app,
                "/d:".to_owned() + &config.rdp.domain,
                "/u:".to_owned() + &config.rdp.username,
                "/p:".to_owned() + &config.rdp.password,
                "/v:".to_owned() + &config.rdp.host,
            ]);
            xfreerdp.spawn().expect("Freerdp execution failed!");
        }
    }
}
