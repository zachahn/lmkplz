extern crate notify;
extern crate libc;

mod safe_wrapper;

use libc::c_char;
use std::time::Duration;
use std::ffi::CStr;
use std::ffi::CString;
use std::path::PathBuf;
use safe_wrapper::*;

#[no_mangle]
pub extern "C" fn new_cwatch(debounce_duration: u64) -> *mut CWatch {
    let boxed_cwatch = safe_new_cwatch(debounce_duration);

    Box::into_raw(boxed_cwatch)
}

#[no_mangle]
pub extern "C" fn add_cwatch(cwatch: *mut CWatch, abspath: *const c_char) {
    unsafe {
        let unsafe_abspath = CStr::from_ptr(abspath);

        safe_add_cwatch(&mut *cwatch, unsafe_abspath.to_str().unwrap());
    }
}

#[no_mangle]
pub extern "C" fn watch_cwatch(cwatch: *mut CWatch,
                               success: extern fn(*const c_char, *const c_char),
                               failure: extern fn(*const c_char),
                               ended: extern fn()) {
    unsafe {
        let wrapped_success_callback = success_callback_wrapper(success);
        let wrapped_failure_callback = failure_callback_wrapper(failure);
        let wrapped_ended_callback = ended_callback_wrapper(ended);

        safe_watch_cwatch(&mut *cwatch, &*wrapped_success_callback, &*wrapped_failure_callback, &*wrapped_ended_callback)
    }
}

fn success_callback_wrapper(callback: extern fn(*const c_char, *const c_char)) -> Box<Fn(SuccessEvent, PathBuf)> {
    Box::new(
        move |event, pathbuf| {
            let status = match event {
                SuccessEvent::Create => "create",
                SuccessEvent::Write => "write",
                SuccessEvent::Remove => "remove",
            };
            let path = pathbuf.to_str().unwrap();

            let cstatus = CString::new(status).unwrap();
            let cpath = CString::new(path).unwrap();

            callback(cstatus.as_ptr(), cpath.as_ptr())
        }
    )
}

fn failure_callback_wrapper(callback: extern fn(*const c_char)) -> Box<Fn(Option<PathBuf>)> {
    Box::new(
        move |o_pathbuf| {
            let path = match o_pathbuf {
                Some(pathbuf) => pathbuf,
                None => PathBuf::from("")
            };

            let cpath = CString::new(path.to_str().unwrap()).unwrap();

            callback(cpath.as_ptr())
        }
    )
}

fn ended_callback_wrapper(callback: extern fn()) -> Box<Fn()> {
    Box::new(move || callback())
}

#[cfg(test)]
mod tests {
    extern crate tempdir;

    use super::*;
    use self::tempdir::TempDir;
    use std::thread::{sleep};
    use std::fs::File;
    use std::io::prelude::*;

    #[test]
    fn unsafe_works() {
        let td = TempDir::new("tmpdir").expect("failed to create tempdir");

        sleep(Duration::from_millis(10));

        let cwatch = new_cwatch(1);
        let path_to_watch = td.path().to_str().expect("can't get tempdir path");
        add_cwatch(cwatch, CString::new(path_to_watch).unwrap().as_ptr());

        sleep(Duration::from_millis(100));

        let file_path = td.path().join("testing.txt");
        let mut f = File::create(file_path).expect("couldn't create file");
        f.write_all(b"Hello, world!").expect("couldn't write to file");
        f.sync_all().expect("couldn't sync file");

        unsafe { (*cwatch).rx.recv().expect("didn't get file") };
    }
}
