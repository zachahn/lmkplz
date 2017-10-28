extern crate notify;
extern crate libc;

mod safe_wrapper;

use libc::c_char;
use std::ffi::{CStr, CString};
use std::path::PathBuf;
use safe_wrapper::*;

/// Create a new instance of the watcher
#[no_mangle]
pub extern "C" fn cwatch_new(debounce_duration: u64) -> *mut CWatch {
    let boxed_cwatch = safe_cwatch_new(debounce_duration);

    Box::into_raw(boxed_cwatch)
}

/// Add a path to watch
#[no_mangle]
pub extern "C" fn cwatch_add(cwatch: *mut CWatch, abspath: *const c_char) {
    unsafe {
        let unsafe_abspath = CStr::from_ptr(abspath);

        safe_cwatch_add(&mut *cwatch, unsafe_abspath.to_str().unwrap());
    }
}

/// Start watching
#[no_mangle]
pub extern "C" fn cwatch_await(cwatch: *mut CWatch,
                               success: extern "C" fn(*const c_char, *const c_char, *const c_char),
                               failure: extern "C" fn(*const c_char),
                               ended: extern "C" fn()) {
    let wrapped_success_callback = success_callback_wrapper(success);
    let wrapped_failure_callback = failure_callback_wrapper(failure);
    let wrapped_ended_callback = ended_callback_wrapper(ended);

    unsafe {
        safe_cwatch_await(&mut *cwatch,
                          &*wrapped_success_callback,
                          &*wrapped_failure_callback,
                          &*wrapped_ended_callback)
    }
}

fn success_callback_wrapper(callback: extern "C" fn(*const c_char, *const c_char, *const c_char))
                            -> Box<Fn(PathBuf, PathBuf, PathBuf)> {
    Box::new(move |modified_pathbuf, added_pathbuf, removed_pathbuf| {
        let modified_path = modified_pathbuf.to_str().unwrap();
        let added_path = added_pathbuf.to_str().unwrap();
        let removed_path = removed_pathbuf.to_str().unwrap();

        let modified_cstr = CString::new(modified_path).unwrap();
        let added_cstr = CString::new(added_path).unwrap();
        let removed_cstr = CString::new(removed_path).unwrap();

        callback(modified_cstr.as_ptr(), added_cstr.as_ptr(), removed_cstr.as_ptr());
    })
}

fn failure_callback_wrapper(callback: extern "C" fn(*const c_char)) -> Box<Fn(Option<PathBuf>)> {
    Box::new(move |o_pathbuf| {
        let path = match o_pathbuf {
            Some(pathbuf) => pathbuf,
            None => PathBuf::from(""),
        };

        let cpath = CString::new(path.to_str().unwrap()).unwrap();

        callback(cpath.as_ptr())
    })
}

fn ended_callback_wrapper(callback: extern "C" fn()) -> Box<Fn()> {
    Box::new(move || callback())
}

#[cfg(test)]
mod tests {
    extern crate tempdir;

    use super::*;
    use self::tempdir::TempDir;
    use std::thread::sleep;
    use std::fs::File;
    use std::time::Duration;
    use std::io::prelude::*;

    #[test]
    fn unsafe_works() {
        let td = TempDir::new("tmpdir").expect("failed to create tempdir");

        sleep(Duration::from_millis(10));

        let cwatch = cwatch_new(1);
        let path_to_watch = td.path().to_str().expect("can't get tempdir path");
        cwatch_add(cwatch, CString::new(path_to_watch).unwrap().as_ptr());

        sleep(Duration::from_millis(100));

        let file_path = td.path().join("testing.txt");
        let mut f = File::create(file_path).expect("couldn't create file");
        f.write_all(b"Hello, world!")
            .expect("couldn't write to file");
        f.sync_all().expect("couldn't sync file");

        unsafe { (*cwatch).rx.recv().expect("didn't get file") };
    }
}
