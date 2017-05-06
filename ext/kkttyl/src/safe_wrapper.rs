use notify::{RecommendedWatcher, Watcher, RecursiveMode, DebouncedEvent};
use std::sync::mpsc::{channel, Receiver};
use std::time::Duration;

pub struct CWatch {
    pub watcher: RecommendedWatcher,
    pub rx: Receiver<DebouncedEvent>
}

pub fn safe_new_cwatch(debounce_duration: u64) -> Box<CWatch> {
    let (transmission, receiving) = channel();
    let watcher: RecommendedWatcher = Watcher::new(transmission, Duration::from_secs(debounce_duration)).unwrap();

    let ws = CWatch { watcher: watcher, rx: receiving };

    Box::new(ws)
}

pub fn safe_add_cwatch(cwatch: &mut CWatch, abspath: &str) {
    cwatch.watcher.watch(abspath, RecursiveMode::Recursive).unwrap();
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
        safe_add_cwatch(&mut cwatch, td.path().to_str().expect("can't get tempdir path"));

        sleep(Duration::from_millis(100));

        let file_path = td.path().join("testing.txt");
        let mut f = File::create(file_path).expect("couldn't create file");
        f.write_all(b"Hello, world!").expect("couldn't write to file");
        f.sync_all().expect("couldn't sync file");

        cwatch.rx.recv().expect("didn't get file");
    }
}
