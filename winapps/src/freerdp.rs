pub mod freerdp_back {
    use crate::RemoteClient;

    struct Freerdp {}

    impl RemoteClient for Freerdp {
        fn check_depends(&self) {
            todo!()
        }

        fn load_config(&self, _path: &str) {
            todo!()
        }

        fn run_app(&self, _app: &str) {
            todo!()
        }
    }
}
