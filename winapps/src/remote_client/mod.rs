use crate::{Config, Result};

pub(crate) mod freerdp;

pub trait RemoteClient {
    fn check_depends(self, config: &Config) -> Result<()>;

    fn run_app(self, config: &Config, exec: String, args: Vec<String>) -> Result<()>;

    fn run_full_session(self, config: &Config) -> Result<()>;
}
