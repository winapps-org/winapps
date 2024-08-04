pub mod freerdp_back {
    use crate::{get_data_dir, unwrap_or_exit, Config, RemoteClient};
    use decompress::{decompressors, ExtractOptsBuilder};
    use indicatif::ProgressBar;
    use regex::Regex;
    use std::cmp::min;
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
            Command::new(get_data_dir().join("bin/xfreerdp"))
        }

        // fn get_freerdp_dir() -> PathBuf {
        //     let path = get_data_dir().join("bin");

        //     if !path.exists() {
        //         let dir = path.clone();
        //         info!(
        //             "Freerdp directory {:?} does not exist! Creating...",
        //             dir.to_str()
        //         );
        //         fs::create_dir_all(dir).expect("Failed to create directory");
        //     }

        //     if !path.is_dir() {
        //         error!("Freerdp directory {:?} is not a directory", path).panic();
        //     }

        //     path
        // }

        async fn install_freerdp() {
            let freerdp_file = "freerdp-3.6.3-1.fc41.x86_64.rpm";
            let bar = ProgressBar::new(1);

            bar.set_style(indicatif::ProgressStyle::with_template(
                            "{spinner:.green} [{elapsed}] {wide_bar:.cyan/blue} {bytes}/{total_bytes} {bytes_per_sec} {msg} ({eta})",
                        ).unwrap().progress_chars("#>-"));
            bar.set_message(format!("Starting {}", freerdp_file));

            bar.tick();

            let response = reqwest::get(
                "https://kojipkgs.fedoraproject.org//packages/freerdp/3.6.3/1.fc41/x86_64/"
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

            let mut tmp_file = tokio::fs::File::create(get_data_dir().join(freerdp_file))
                .await
                .unwrap();

            while let Some(item) = stream.next().await {
                tokio::io::copy(&mut item.unwrap().as_ref(), &mut tmp_file)
                    .await
                    .unwrap();
            }

            // let mut decoder =
            //     async_compression::tokio::bufread::ZstdDecoder::new(StreamReader::new(stream));

            // let mut target = tokio::fs::File::create(get_data_dir().join("bin1"))
            //     .await
            //     .unwrap();

            // io::copy(&mut decoder, &mut target).await.unwrap();

            // let file = tokio::fs::File::create(get_data_dir().join("bin1"))
            //     .await
            //     .unwrap();

            let decompressor =
                decompress::Decompress::build(vec![decompressors::zstd::Zstd::build(Some(
                    Regex::new(r".*").unwrap(),
                ))]);

            let res = decompressor.decompress(
                get_data_dir()
                    .join("freerdp-3.6.3-1.fc41.x86_64.zst")
                    .as_path(),
                get_data_dir().join("bin").as_path(),
                &ExtractOptsBuilder::default().build().unwrap(),
            );

            info!("{res:?}");
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
