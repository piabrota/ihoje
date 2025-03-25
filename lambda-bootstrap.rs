use lambda_runtime::{service_fn, LambdaEvent, Error};
use serde_json::{json, Value};
use std::process::Command;
use std::env;

async fn handler(event: LambdaEvent<Value>) -> Result<Value, Error> {
    // Extract parameters from the event
    let city = event.payload.get("city")
        .and_then(|v| v.as_str())
        .unwrap_or("FL");
    
    let api_key = event.payload.get("firecrawl_api_key")
        .and_then(|v| v.as_str())
        .unwrap_or_else(|| env::var("FIRECRAWL_API_KEY").unwrap_or_default().as_str());
        
    let target_url = event.payload.get("target_url")
        .and_then(|v| v.as_str())
        .unwrap_or_else(|| env::var("TARGET_URL").unwrap_or_default().as_str());
    
    // Set environment variables for the scraper
    env::set_var("CITY", city);
    env::set_var("FIRECRAWL_API_KEY", api_key);
    env::set_var("TARGET_URL", target_url);
    
    // Execute the rust-scraper binary
    let output = Command::new("./rust-scraper")
        .output()
        .map_err(|e| format!("Failed to execute scraper: {}", e))?;
    
    // Prepare response
    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();
    let success = output.status.success();
    
    let response = json!({
        "success": success,
        "exit_code": output.status.code(),
        "stdout": stdout,
        "stderr": stderr,
        "city": city
    });
    
    Ok(response)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    // Initialize the Lambda runtime
    lambda_runtime::run(service_fn(handler)).await?;
    Ok(())
}