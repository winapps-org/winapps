pub mod freerdp {
    use crate::RemoteClient;

    struct Freerdp {}

    impl RemoteClient for Freerdp {
        fn check_depends(&self) {
            todo!()
        }

        fn load_config(&self, path: &str) {
            todo!()
        }

        fn run_app(&self, app: &str) {
            todo!()
        }
    }
}
