pub mod freerdp_back {
    use std::process::{Command, Stdio};

    use crate::{Config, RemoteClient};

    pub struct Freerdp {}

    impl RemoteClient for Freerdp {
        fn check_depends(&self, config: Config) {
            let mut xfreerdp = Command::new("xfreerdp");
            xfreerdp.stdout(Stdio::null());
            xfreerdp.stderr(Stdio::null());
            xfreerdp.args(["-h"]);
            xfreerdp
                .spawn()
                .expect("Freerdp execution failed! It needs to be installed!");
            println!("Freerdp found!");

            println!("All dependencies found!");
            println!("Running explorer as test!");
            println!("Check yourself if it appears correctly!");

            self.run_app(config, Some(&"explorer.exe".to_string()));

            println!("Test finished!");
        }

        fn run_app(&self, config: Config, app: Option<&String>) {
            let mut xfreerdp = Command::new("xfreerdp");
            xfreerdp.stdout(Stdio::null());
            xfreerdp.stderr(Stdio::null());
            match app {
                Some(exe) => {
                    xfreerdp.args([
                        &format!("/app:{}", exe),
                        &format!("/d:{}", &config.rdp.domain),
                        &format!("/u:{}", &config.rdp.username),
                        &format!("/p:{}", &config.rdp.password),
                        &format!("/v:{}", &config.rdp.host),
                        "/dynamic-resolution",
                        "+auto-reconnect",
                        "+clipboard",
                        "+home-drive",
                    ]);
                }
                None => {
                    xfreerdp.args([
                        &format!("/d:{}", &config.rdp.domain),
                        &format!("/u:{}", &config.rdp.username),
                        &format!("/p:{}", &config.rdp.password),
                        &format!("/v:{}", &config.rdp.host),
                        "/dynamic-resolution",
                        "+auto-reconnect",
                        "+clipboard",
                        "+home-drive",
                    ]);
                }
            }
            xfreerdp.spawn().expect("Freerdp execution failed!");
        }
    }
}
