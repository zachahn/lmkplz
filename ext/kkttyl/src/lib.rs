extern crate notify;
extern crate libc;

mod safe_wrapper;
mod callback_util;
mod string_util;

use libc::c_char;
use std::ffi::{CStr, CString};
use std::path::PathBuf;
use safe_wrapper::CWatch;

/// Create a new instance of the watcher
#[no_mangle]
pub extern "C" fn cwatch_new(debounce_duration: u64) -> *mut CWatch {
    let boxed_cwatch = safe_wrapper::safe_cwatch_new(debounce_duration);

    Box::into_raw(boxed_cwatch)
}

/// Add a path to watch
#[no_mangle]
pub extern "C" fn cwatch_add(cwatch: *mut CWatch, abspath: *const c_char) {
    unsafe {
        let unsafe_abspath = CStr::from_ptr(abspath);

        safe_wrapper::safe_cwatch_add(&mut *cwatch, unsafe_abspath.to_str().unwrap());
    }
}

/// Be notified of a change
#[no_mangle]
pub extern "C" fn cwatch_await(
    cwatch: *mut CWatch,
    timeout_duration: u64,
    success: extern "C" fn(*const c_char, *const c_char, *const c_char),
    failure: extern "C" fn(),
    timeout: extern "C" fn(),
    ended: extern "C" fn(),
) {
    let wrapped_success_callback = success_callback_wrapper(success);
    let wrapped_failure_callback = callback_util::wrap_no_arg(failure);
    let wrapped_timeout_callback = callback_util::wrap_no_arg(timeout);
    let wrapped_ended_callback = callback_util::wrap_no_arg(ended);

    unsafe {
        safe_wrapper::safe_cwatch_await(
            &mut *cwatch,
            timeout_duration,
            &*wrapped_success_callback,
            &*wrapped_failure_callback,
            &*wrapped_timeout_callback,
            &*wrapped_ended_callback,
        )
    }
}

fn success_callback_wrapper(
    callback: extern "C" fn(*const c_char, *const c_char, *const c_char),
) -> Box<Fn(PathBuf, PathBuf, PathBuf)> {
    Box::new(move |modified_pathbuf, created_cstring, removed_pathbuf| {
        let modified_cstring = string_util::pathbuf_to_cstring(modified_pathbuf);
        let created_cstring = string_util::pathbuf_to_cstring(created_cstring);
        let removed_cstring = string_util::pathbuf_to_cstring(removed_pathbuf);

        callback(
            modified_cstring.as_ptr(),
            created_cstring.as_ptr(),
            removed_cstring.as_ptr(),
        );
    })
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
        f.write_all(b"Hello, world!").expect(
            "couldn't write to file",
        );
        f.sync_all().expect("couldn't sync file");

        unsafe { (*cwatch).rx.recv().expect("didn't get file") };
    }
}
