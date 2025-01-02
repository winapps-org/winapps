use crate::Result;

pub(crate) mod freerdp;

pub trait RemoteClient {
    fn check_depends(&self) -> Result<()>;

    fn run_executable(&self, exec: String) -> Result<()>;

    fn run_windows(&self) -> Result<()>;
}
