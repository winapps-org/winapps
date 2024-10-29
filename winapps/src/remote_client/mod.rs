use crate::Config;

pub(crate) mod freerdp;

pub trait RemoteClient {
    fn check_depends(&self, config: &Config);

    fn run_executable(&self, config: &Config, exec: String);

    fn run_windows(&self, config: &Config);
}
