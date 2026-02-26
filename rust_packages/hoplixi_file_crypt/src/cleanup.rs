use std::fs;
use std::path::PathBuf;

/// Collects paths to temporary files and removes them on drop.
///
/// Guarantees cleanup on both success and error paths.
/// Call [`finish`] when done — it removes all tracked files
/// and disarms the guard so `drop` is a no-op.
pub struct TempCleanup {
    pub paths: Vec<PathBuf>,
}

impl TempCleanup {
    pub fn new() -> Self {
        Self { paths: Vec::new() }
    }

    /// Register a path for removal.
    pub fn track(&mut self, path: PathBuf) {
        self.paths.push(path);
    }

    /// Remove a specific file immediately and stop tracking it.
    pub fn remove_now(&mut self, path: &PathBuf) {
        let _ = fs::remove_file(path);
        self.paths.retain(|p| p != path);
    }

    /// Clean up all tracked files and disarm the guard.
    pub fn finish(&mut self) {
        for p in self.paths.drain(..) {
            let _ = fs::remove_file(&p);
        }
    }
}

impl Drop for TempCleanup {
    fn drop(&mut self) {
        // If `finish()` was already called, `paths` is empty.
        for p in &self.paths {
            let _ = fs::remove_file(p);
        }
    }
}
