pub fn wrap_no_arg(callback: extern "C" fn()) -> Box<Fn()> {
    Box::new(move || callback())
}
