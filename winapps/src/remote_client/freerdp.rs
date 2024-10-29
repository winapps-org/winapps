use derive_new::new;
use indicatif::ProgressBar;
use std::cmp::min;
use std::fs::File;
use std::process::{Command, Stdio};
use tokio_stream::StreamExt;
use tracing::{info, warn};

use crate::backend::Backend;
use crate::remote_client::RemoteClient;
use crate::{unwrap_or_exit, Config};

#[derive(new)]
pub struct Freerdp {}

impl Freerdp {
    fn get_freerdp(config: &Config) -> Command {
        /*
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
            .unwrap()
            .block_on(Freerdp::install_freerdp());

        Command::new(
            Config::get_data_path(None)
                .unwrap()
                .join("usr/bin/xfreerdp"),
        )
         */

        let mut command = Command::new("xfreerdp");

        command.stdout(Stdio::null()).stderr(Stdio::null()).args([
            &format!("/d:{}", &config.auth.domain),
            &format!("/u:{}", &config.auth.username),
            &format!("/p:{}", &config.auth.password),
            &format!("/v:{}", &config.get_backend().get_host(config)),
            "/dynamic-resolution",
            "+auto-reconnect",
            "+clipboard",
            "+home-drive",
        ]);

        command
    }

    // TODO: This is dead atm for testing
    async fn install_freerdp() {
        let data_path = Config::get_data_path(None).unwrap();

        if data_path.join("usr/bin/xfreerdp").exists() {
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
            "https://kojipkgs.fedoraproject.org/packages/freerdp/3.6.3/1.fc41/x86_64/".to_owned()
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

        let mut file = tokio::fs::File::create(data_path.join(freerdp_file))
            .await
            .unwrap();

        while let Some(item) = stream.next().await {
            tokio::io::copy(&mut item.unwrap().as_ref(), &mut file)
                .await
                .unwrap();
        }

        let mut rpm2cpio = Command::new("rpm2cpio");
        rpm2cpio.stdin(Stdio::from(
            File::open(data_path.join(freerdp_file)).unwrap(),
        ));
        rpm2cpio.stdout(Stdio::piped());
        rpm2cpio.stderr(Stdio::null());
        rpm2cpio.current_dir(data_path.clone());

        let rpm2cpio = unwrap_or_exit!(
            rpm2cpio.spawn(),
            "rpm2cpio execution failed! Check if rpm2cpio (rpm) is installed!",
        );

        let mut cpio = Command::new("cpio");
        cpio.stdin(Stdio::from(rpm2cpio.stdout.unwrap()));
        cpio.stdout(Stdio::null());
        cpio.stderr(Stdio::null());
        cpio.current_dir(data_path);
        cpio.arg("-idmv");

        unwrap_or_exit!(
            cpio.spawn(),
            "cpio execution failed! Check if cpio is installed!",
        );
    }
}

impl RemoteClient for Freerdp {
    fn check_depends(&self, config: &Config) {
        let mut xfreerdp = Freerdp::get_freerdp(config);
        xfreerdp.stdout(Stdio::null());
        xfreerdp.stderr(Stdio::null());
        xfreerdp.arg("-h");

        unwrap_or_exit!(
            xfreerdp.spawn(),
            "Freerdp execution failed! Try to delete {} to force a reinstall.",
            Config::get_data_path(None).unwrap().join("usr").display(),
        );

        info!("Freerdp found!");

        info!("All dependencies found!");
        info!("Running explorer as test!");
        warn!("Check yourself if it appears correctly!");

        self.run_executable(config, "explorer.exe".to_string());

        info!("Test finished!");
    }

    fn run_executable(&self, config: &Config, app: String) {
        let mut xfreerdp = Freerdp::get_freerdp(config);
        xfreerdp.arg(format!("/app:{app}"));

        unwrap_or_exit!(
            xfreerdp.spawn(),
            "Freerdp execution failed, check logs above!",
        );
    }

    fn run_windows(&self, config: &Config) {
        unwrap_or_exit!(
            Freerdp::get_freerdp(config).spawn(),
            "Freerdp execution failed, check logs above!",
        );
    }
}
