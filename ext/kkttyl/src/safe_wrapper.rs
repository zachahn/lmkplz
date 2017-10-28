use notify::{RecommendedWatcher, Watcher, RecursiveMode, DebouncedEvent};
use std::sync::mpsc::{channel, Receiver};
use std::time::Duration;
use std::path::PathBuf;

pub struct CWatch {
    pub watcher: RecommendedWatcher,
    pub rx: Receiver<DebouncedEvent>,
}

pub fn safe_cwatch_new(debounce_duration: u64) -> Box<CWatch> {
    let (transmission, receiving) = channel();
    let watcher: RecommendedWatcher =
        Watcher::new(transmission, Duration::from_secs(debounce_duration)).unwrap();

    let ws = CWatch {
        watcher: watcher,
        rx: receiving,
    };

    Box::new(ws)
}

pub fn safe_cwatch_add(cwatch: &mut CWatch, abspath: &str) {
    cwatch
        .watcher
        .watch(abspath, RecursiveMode::Recursive)
        .unwrap();
}

pub fn safe_cwatch_await(cwatch: &mut CWatch,
                         success_callback: &Fn(PathBuf, PathBuf, PathBuf),
                         failure_callback: &Fn(Option<PathBuf>),
                         ended_callback: &Fn()) {
    match cwatch.rx.recv() {
        Ok(notify_event) => {
            match notify_event {
                DebouncedEvent::Create(pathbuf) => {
                    success_callback(PathBuf::new(), pathbuf, PathBuf::new())
                }
                DebouncedEvent::Write(pathbuf) => {
                    success_callback(pathbuf, PathBuf::new(), PathBuf::new())
                }
                DebouncedEvent::Remove(pathbuf) => {
                    success_callback(PathBuf::new(), PathBuf::new(), pathbuf)
                }
                DebouncedEvent::Rename(sourcepath, destpath) => {
                    success_callback(PathBuf::new(), destpath, sourcepath)
                }
                DebouncedEvent::Error(_, pathbuf) => {
                    failure_callback(pathbuf)
                }
                _ => {}
            };
        }
        Err(_) => ended_callback()
    }
}

#[cfg(test)]
mod tests {
    extern crate tempdir;

    use super::*;
    use self::tempdir::TempDir;
    use std::thread::sleep;
    use std::fs::File;
    use std::io::prelude::*;

    #[test]
    fn safe_works() {
        let td = TempDir::new("tmpdir").expect("failed to create tempdir");

        sleep(Duration::from_millis(10));

        let mut cwatch = safe_cwatch_new(1);
        safe_cwatch_add(&mut cwatch,
                        td.path().to_str().expect("can't get tempdir path"));

        sleep(Duration::from_millis(100));

        let file_path = td.path().join("testing.txt");
        let mut f = File::create(file_path).expect("couldn't create file");
        f.write_all(b"Hello, world!")
            .expect("couldn't write to file");
        f.sync_all().expect("couldn't sync file");

        let test_success_cb = Box::new(move |_m: PathBuf, _a: PathBuf, _r: PathBuf| {
        });

        let test_failure_cb = Box::new(move |_: Option<PathBuf>| {
        });

        let test_ended_cb = Box::new(move || {
        });

        safe_cwatch_await(&mut cwatch, &*test_success_cb, &*test_failure_cb, &*test_ended_cb);

        // cwatch.rx.recv().expect("didn't get file");
    }
}
