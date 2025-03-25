use anyhow::{Result, Context};
use chrono::Utc;
use std::fs::{File, OpenOptions};
use std::io::Write;
use std::path::Path;

pub struct Logger {
    file_path: String,
}

impl Logger {
    pub fn new(file_path: String) -> Result<Self> {
        // Ensure the directory exists
        if let Some(parent) = Path::new(&file_path).parent() {
            if !parent.exists() {
                std::fs::create_dir_all(parent)?;
            }
        }
        
        // Create the log file if it doesn't exist
        if !Path::new(&file_path).exists() {
            File::create(&file_path)
                .context(format!("Failed to create log file: {}", file_path))?;
        }
        
        Ok(Self { file_path })
    }
    
    pub fn log(&self, level: &str, message: &str) -> Result<()> {
        let timestamp = Utc::now().format("%Y-%m-%dT%H:%M:%S%.3fZ").to_string();
        let log_entry = format!("[{}] {} - {}\n", timestamp, level, message);
        
        let mut file = OpenOptions::new()
            .append(true)
            .open(&self.file_path)
            .context(format!("Failed to open log file: {}", self.file_path))?;
            
        file.write_all(log_entry.as_bytes())
            .context("Failed to write to log file")?;
            
        Ok(())
    }
    
    pub fn info(&self, message: &str) -> Result<()> {
        self.log("INFO", message)
    }
    
    #[allow(dead_code)]
    pub fn error(&self, message: &str) -> Result<()> {
        self.log("ERROR", message)
    }
    
    #[allow(dead_code)]
    pub fn warn(&self, message: &str) -> Result<()> {
        self.log("WARN", message)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::io::Read;
    use std::path::Path;
    
    #[test]
    fn test_logger_creation() {
        let log_path = "target/test_logger.log";
        
        // Clean up any existing file
        if Path::new(log_path).exists() {
            fs::remove_file(log_path).unwrap();
        }
        
        // Create new logger
        let _logger = Logger::new(log_path.to_string()).unwrap();
        
        // Verify file was created
        assert!(Path::new(log_path).exists());
        
        // Clean up
        fs::remove_file(log_path).unwrap();
    }
    
    #[test]
    fn test_logger_log_message() {
        let log_path = "target/test_logger_message.log";
        
        // Clean up any existing file
        if Path::new(log_path).exists() {
            fs::remove_file(log_path).unwrap();
        }
        
        // Create logger and write messages
        let logger = Logger::new(log_path.to_string()).unwrap();
        logger.info("Test info message").unwrap();
        logger.error("Test error message").unwrap();
        logger.warn("Test warning message").unwrap();
        
        // Read file contents
        let mut file = fs::File::open(log_path).unwrap();
        let mut contents = String::new();
        file.read_to_string(&mut contents).unwrap();
        
        // Verify log messages
        assert!(contents.contains("INFO - Test info message"));
        assert!(contents.contains("ERROR - Test error message"));
        assert!(contents.contains("WARN - Test warning message"));
        
        // Clean up
        fs::remove_file(log_path).unwrap();
    }
}