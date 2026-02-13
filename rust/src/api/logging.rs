use std::sync::{Mutex, OnceLock};
use std::time::{SystemTime, UNIX_EPOCH};

use crate::frb_generated::StreamSink;
use log::{Level, LevelFilter, Metadata, Record};

#[derive(Clone, Debug)]
pub struct LogEntry {
    pub time_millis: i64,
    pub level: i32,
    pub tag: String,
    pub msg: String,
}

const LEVEL_DEBUG: i32 = 10;
const LEVEL_INFO: i32 = 20;
const LEVEL_WARNING: i32 = 30;
const LEVEL_ERROR: i32 = 40;
const LEVEL_FATAL: i32 = 50;

static LOG_STREAM_SINK: OnceLock<Mutex<Option<StreamSink<LogEntry>>>> = OnceLock::new();
static LOGGER_INIT: OnceLock<()> = OnceLock::new();

fn sink_slot() -> &'static Mutex<Option<StreamSink<LogEntry>>> {
    LOG_STREAM_SINK.get_or_init(|| Mutex::new(None))
}

fn now_millis() -> i64 {
    match SystemTime::now().duration_since(UNIX_EPOCH) {
        Ok(duration) => duration.as_millis() as i64,
        Err(_) => 0,
    }
}

fn to_level_filter(level: i32) -> LevelFilter {
    match level {
        level if level <= LEVEL_DEBUG => LevelFilter::Debug,
        level if level <= LEVEL_INFO => LevelFilter::Info,
        level if level <= LEVEL_WARNING => LevelFilter::Warn,
        level if level <= LEVEL_ERROR => LevelFilter::Error,
        _ => LevelFilter::Error,
    }
}

fn map_log_level(level: Level) -> i32 {
    match level {
        Level::Trace => LEVEL_DEBUG,
        Level::Debug => LEVEL_DEBUG,
        Level::Info => LEVEL_INFO,
        Level::Warn => LEVEL_WARNING,
        Level::Error => LEVEL_ERROR,
    }
}

fn push_to_dart(level: i32, tag: String, msg: String) {
    let entry = LogEntry {
        time_millis: now_millis(),
        level,
        tag,
        msg,
    };

    if let Ok(guard) = sink_slot().lock() {
        if let Some(sink) = guard.as_ref() {
            let _ = sink.add(entry);
        }
    }
}

struct FrbRustLogger {}

impl log::Log for FrbRustLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= log::max_level()
    }

    fn log(&self, record: &Record) {
        if !self.enabled(record.metadata()) {
            return;
        }

        let tag = if record.target().is_empty() {
            "Rust".to_string()
        } else {
            record.target().to_string()
        };

        push_to_dart(
            map_log_level(record.level()),
            tag,
            record.args().to_string(),
        );
    }

    fn flush(&self) {}
}

static FRB_RUST_LOGGER: FrbRustLogger = FrbRustLogger {};

pub fn create_log_stream(sink: StreamSink<LogEntry>) {
    if let Ok(mut guard) = sink_slot().lock() {
        *guard = Some(sink);
    }
}

pub fn install_rust_log_bridge(level: i32) -> Result<(), String> {
    let filter = to_level_filter(level);

    if LOGGER_INIT.get().is_some() {
        log::set_max_level(filter);
        return Ok(());
    }

    log::set_logger(&FRB_RUST_LOGGER).map_err(|err| format!("Failed to set rust logger: {err}"))?;

    let _ = LOGGER_INIT.set(());
    log::set_max_level(filter);

    Ok(())
}

pub fn rust_log(level: i32, tag: String, msg: String) {
    push_to_dart(level, tag, msg);
}

pub fn rust_log_debug(tag: String, msg: String) {
    push_to_dart(LEVEL_DEBUG, tag, msg);
}

pub fn rust_log_info(tag: String, msg: String) {
    push_to_dart(LEVEL_INFO, tag, msg);
}

pub fn rust_log_warning(tag: String, msg: String) {
    push_to_dart(LEVEL_WARNING, tag, msg);
}

pub fn rust_log_error(tag: String, msg: String) {
    push_to_dart(LEVEL_ERROR, tag, msg);
}

pub fn rust_log_fatal(tag: String, msg: String) {
    push_to_dart(LEVEL_FATAL, tag, msg);
}
