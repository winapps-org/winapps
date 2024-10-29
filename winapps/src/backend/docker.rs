use crate::backend::Backend;
use crate::config::Config;

pub struct Docker {}

impl Backend for Docker {
    fn check_depends(&self, config: &Config) {
        todo!()
    }

    fn start(&self, config: &Config) {
        todo!()
    }

    fn get_host(&self, _: &Config) -> String {
        "127.0.0.1".to_string()
    }
}
