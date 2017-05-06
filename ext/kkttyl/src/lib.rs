extern crate notify;
extern crate libc;

use notify::{RecommendedWatcher, Watcher, RecursiveMode, DebouncedEvent};
use std::sync::mpsc::{channel, Receiver};
use std::time::Duration;
use libc::{c_char};
use std::ffi::CStr;
use std::ffi::CString;

pub struct CWatch {
    watcher: RecommendedWatcher,
    rx: Receiver<DebouncedEvent>
}

fn safe_new_cwatch(debounce_duration: u64) -> Box<CWatch> {
    let (transmission, receiving) = channel();
    let watcher: RecommendedWatcher = Watcher::new(transmission, Duration::from_secs(debounce_duration)).unwrap();

    let ws = CWatch { watcher: watcher, rx: receiving };

    Box::new(ws)
}

fn safe_watch_cwatch(cwatch: &mut CWatch, abspath: &str) {
    cwatch.watcher.watch(abspath, RecursiveMode::Recursive).unwrap();
}

#[no_mangle]
pub extern "C" fn new_cwatch(debounce_duration: u64) -> *mut CWatch {
    let boxed_cwatch = safe_new_cwatch(debounce_duration);

    Box::into_raw(boxed_cwatch)
}

#[no_mangle]
pub extern "C" fn watch_cwatch(cwatch: *mut CWatch, abspath: *const c_char) {
    unsafe {
        let unsafe_abspath = CStr::from_ptr(abspath);

        safe_watch_cwatch(&mut *cwatch, unsafe_abspath.to_str().unwrap());
    }
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
    fn safe_works() {
        let td = TempDir::new("tmpdir").expect("failed to create tempdir");

        sleep(Duration::from_millis(10));

        let mut cwatch = safe_new_cwatch(1);
        safe_watch_cwatch(&mut cwatch, td.path().to_str().expect("can't get tempdir path"));

        sleep(Duration::from_millis(100));

        let file_path = td.path().join("testing.txt");
        let mut f = File::create(file_path).expect("couldn't create file");
        f.write_all(b"Hello, world!").expect("couldn't write to file");
        f.sync_all().expect("couldn't sync file");

        cwatch.rx.recv().expect("didn't get file");
    }

    #[test]
    fn unsafe_works() {
        let td = TempDir::new("tmpdir").expect("failed to create tempdir");

        sleep(Duration::from_millis(10));

        let cwatch = new_cwatch(1);
        let path_to_watch = td.path().to_str().expect("can't get tempdir path");
        watch_cwatch(cwatch, CString::new(path_to_watch).unwrap().as_ptr());

        sleep(Duration::from_millis(100));

        let file_path = td.path().join("testing.txt");
        let mut f = File::create(file_path).expect("couldn't create file");
        f.write_all(b"Hello, world!").expect("couldn't write to file");
        f.sync_all().expect("couldn't sync file");

        unsafe { (*cwatch).rx.recv().expect("didn't get file") };
    }
}
