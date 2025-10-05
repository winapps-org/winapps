use crate::Result;

pub(crate) mod freerdp;

pub trait RemoteClient {
    fn check_depends(&self) -> Result<()>;

    fn run_app(&self, exec: String, args: Vec<String>) -> Result<()>;

    fn run_full_session(&self) -> Result<()>;
}
