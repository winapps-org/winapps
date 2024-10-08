pub mod freerdp_back {
    use crate::{get_data_dir, unwrap_or_exit, Config, RemoteClient};
    use indicatif::ProgressBar;
    use std::cmp::min;
    use std::fs::File;
    use std::process::{Command, Stdio};
    use tokio_stream::StreamExt;
    use tracing::{info, warn};

    pub struct Freerdp {}

    impl Freerdp {
        fn get_freerdp() -> Command {
            tokio::runtime::Builder::new_multi_thread()
                .enable_all()
                .build()
                .unwrap()
                .block_on(Freerdp::install_freerdp());
            Command::new(get_data_dir().join("usr/bin/xfreerdp"))
        }

        async fn install_freerdp() {
            if get_data_dir().join("usr/bin/xfreerdp").exists() {
                return;
            }

            let freerdp_file = "freerdp-3.6.3-1.fc41.x86_64.rpm";

            let bar = ProgressBar::new(1);

            bar.set_style(indicatif::ProgressStyle::with_template(
                            "{spinner:.green} [{elapsed}] {wide_bar:.cyan/blue} {bytes}/{total_bytes} {bytes_per_sec} {msg} ({eta})",
                        ).unwrap().progress_chars("#>-"));
            bar.set_message(format!("Starting {}", freerdp_file));

            bar.tick();

            let response = reqwest::get(
                "https://kojipkgs.fedoraproject.org/packages/freerdp/3.6.3/1.fc41/x86_64/"
                    .to_owned()
                    + freerdp_file,
            )
            .await
            .unwrap();

            let total_size = response.content_length().unwrap_or(0);

            bar.set_length(total_size);
            bar.set_message(format!("Downloading {}", freerdp_file));

            let mut downloaded: u64 = 0;

            let mut stream = response.bytes_stream().map(|result| {
                result
                    .inspect(|result| {
                        let new = min(downloaded + (result.len() as u64), total_size);
                        downloaded = new;
                        bar.set_position(new);
                    })
                    .map_err(|err| std::io::Error::new(std::io::ErrorKind::Other, err))
            });

            let mut file = tokio::fs::File::create(get_data_dir().join(freerdp_file))
                .await
                .unwrap();

            while let Some(item) = stream.next().await {
                tokio::io::copy(&mut item.unwrap().as_ref(), &mut file)
                    .await
                    .unwrap();
            }

            let mut rpm2cpio = Command::new("rpm2cpio");
            rpm2cpio.stdin(Stdio::from(
                File::open(get_data_dir().join(freerdp_file)).unwrap(),
            ));
            rpm2cpio.stdout(Stdio::piped());
            rpm2cpio.stderr(Stdio::null());
            rpm2cpio.current_dir(get_data_dir());

            let rpm2cpio = unwrap_or_exit!(
                rpm2cpio.spawn(),
                "rpm2cpio execution failed! Check if rpm2cpio (rpm) is installed!",
            );

            let mut cpio = Command::new("cpio");
            cpio.stdin(Stdio::from(rpm2cpio.stdout.unwrap()));
            cpio.stdout(Stdio::null());
            cpio.stderr(Stdio::null());
            cpio.current_dir(get_data_dir());
            cpio.arg("-idmv");

            unwrap_or_exit!(
                cpio.spawn(),
                "cpio execution failed! Check if cpio is installed!",
            );
        }
    }

    impl RemoteClient for Freerdp {
        fn check_depends(&self, config: Config) {
            let mut xfreerdp = Freerdp::get_freerdp();
            xfreerdp.stdout(Stdio::null());
            xfreerdp.stderr(Stdio::null());
            xfreerdp.args(["-h"]);

            unwrap_or_exit!(
                xfreerdp.spawn(),
                "Freerdp execution failed! Try to delete {}, to force a reinstall.",
                get_data_dir().join("usr").display(),
            );

            info!("Freerdp found!");

            info!("All dependencies found!");
            info!("Running explorer as test!");
            warn!("Check yourself if it appears correctly!");

            self.run_app(config, Some(&"explorer.exe".to_string()));

            info!("Test finished!");
        }

        fn run_app(&self, config: Config, app: Option<&String>) {
            let mut xfreerdp = Freerdp::get_freerdp();
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
