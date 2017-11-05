use std::path::PathBuf;
use std::ffi::CString;

pub fn pathbuf_to_cstring(pathbuf: PathBuf) -> CString {
    let path_str = pathbuf.to_str().unwrap();

    CString::new(path_str).unwrap()
}
