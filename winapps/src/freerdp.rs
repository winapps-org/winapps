pub mod freerdp_back {
    use std::process::{Command, Stdio};
    use tracing::{info, warn};

    use crate::{unwrap_or_exit, Config, RemoteClient};

    pub struct Freerdp {}

    impl RemoteClient for Freerdp {
        fn check_depends(&self, config: Config) {
            let mut xfreerdp = Command::new("xfreerdp");
            xfreerdp.stdout(Stdio::null());
            xfreerdp.stderr(Stdio::null());
            xfreerdp.args(["-h"]);

            unwrap_or_exit!(
                xfreerdp.spawn(),
                "Freerdp execution failed! It needs to be installed!",
            );

            info!("Freerdp found!");

            info!("All dependencies found!");
            info!("Running explorer as test!");
            warn!("Check yourself if it appears correctly!");

            self.run_app(config, Some(&"explorer.exe".to_string()));

            info!("Test finished!");
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

            unwrap_or_exit!(
                xfreerdp.spawn(),
                "Freerdp execution failed, check logs above!",
            );
        }
    }
}
