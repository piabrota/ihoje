import gleam/io
import gleam/result
import gleam/string
import gleam/list
import shellout

pub type DependencyStatus {
  Available
  Missing
  Misconfigured(String)
}

pub type SystemComponent {
  Docker
  Curl
  Gcloud
  Postgres
  BraveApiKey
  Hadolint
  Pulumi
}

pub fn main() {
  io.println("Toji - System Doctor starting...")
  
  let all_checks = [
    check_docker(),
    check_curl(),
    check_gcloud(),
    check_postgres(),
    check_brave_api_key(),
    check_hadolint(),
    check_pulumi(),
  ]
  
  let failures = list.filter(all_checks, fn(result) {
    case result {
      #(_, Available) -> False
      _ -> True
    }
  })
  
  // Print status of all components
  io.println("\n=== System Components Status ===")
  
  // First print all available components
  let available_components = list.filter(all_checks, fn(result) {
    case result {
      #(_, Available) -> True
      _ -> False
    }
  })
  list.each(available_components, print_dependency_status)
  
  // Then print failures
  case list.length(failures) {
    0 -> {
      io.println("\n✅ All system components are properly configured.")
    }
    _ -> {
      io.println("\n⚠️ Some system components are missing or misconfigured:")
      list.each(failures, print_dependency_status)
    }
  }
  
  // Print detailed PostgreSQL information if available
  case string.is_empty(postgres_details) {
    False -> {
      io.println("\n=== PostgreSQL Detailed Information ===")
      io.println(postgres_details)
    }
    True -> Nil
  }
  
  // Final summary message
  io.println("\n=== System Check Complete ===")
}

fn print_dependency_status(status: #(SystemComponent, DependencyStatus)) {
  let #(component, status) = status
  let component_name = case component {
    Docker -> "Docker"
    Curl -> "curl"
    Gcloud -> "Google Cloud CLI"
    Postgres -> "PostgreSQL"
    BraveApiKey -> "Brave Search API Key"
    Hadolint -> "Hadolint (Docker Linter)"
    Pulumi -> "Pulumi IaC Tool"
  }
  
  case status {
    Available -> io.println("  ✅ " <> component_name <> " is available")
    Missing -> io.println("  ❌ " <> component_name <> " is missing")
    Misconfigured(reason) -> {
      // Special case for PostgreSQL when it's actually available but we have details to show
      case component, string.starts_with(reason, "Available") {
        Postgres, True -> {
          io.println("  ✅ " <> component_name <> " is available")
          // Print the details part which follows "Available - See details below:"
          case string.split(reason, "Available - See details below:") {
            [_, details] -> io.println(details)
            _ -> Nil
          }
        }
        _, _ -> io.println("  ⚠️  " <> component_name <> " is misconfigured: " <> reason)
      }
    }
  }
}

fn check_command(command: String) -> DependencyStatus {
  case shellout.command("which " <> command) {
    Ok(_) -> Available
    Error(_) -> Missing
  }
}

fn check_docker() -> #(SystemComponent, DependencyStatus) {
  #(Docker, check_command("docker"))
}

fn check_curl() -> #(SystemComponent, DependencyStatus) {
  #(Curl, check_command("curl"))
}

fn check_gcloud() -> #(SystemComponent, DependencyStatus) {
  #(Gcloud, check_command("gcloud"))
}

fn get_postgres_tables_info() -> Result(String, String) {
  // Use a shell script to collect comprehensive information about tables
  let script = "
    echo '\\nTables and Columns:'
    psql -h localhost -U postgres -c \"
      SELECT
        table_schema,
        table_name,
        (SELECT COUNT(*) FROM information_schema.columns 
         WHERE table_schema=t.table_schema AND table_name=t.table_name) AS column_count
      FROM information_schema.tables t
      WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      ORDER BY table_schema, table_name;
    \"
    
    echo '\\nViews in the Database:'
    psql -h localhost -U postgres -c \"
      SELECT
        table_schema,
        table_name AS view_name,
        view_definition
      FROM information_schema.views
      WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      ORDER BY table_schema, table_name;
    \"
    
    echo '\\nTable Row Counts:'
    psql -h localhost -U postgres -c \"
      SELECT
        'events' AS table_name,
        COUNT(*) AS row_count
      FROM events
      UNION ALL
      SELECT
        'failed_price_fetches' AS table_name,
        COUNT(*) AS row_count
      FROM failed_price_fetches
      ORDER BY table_name;
    \"
    
    echo '\\nEvents by City:'
    psql -h localhost -U postgres -c \"
      SELECT
        city,
        COUNT(*) AS event_count
      FROM events
      GROUP BY city
      ORDER BY COUNT(*) DESC;
    \"
    
    echo '\\nUpcoming Events Count:'
    psql -h localhost -U postgres -c \"
      SELECT COUNT(*) AS upcoming_event_count
      FROM upcoming_events;
    \"
    
    echo '\\nRecent Failures Count:'
    psql -h localhost -U postgres -c \"
      SELECT COUNT(*) AS recent_failures
      FROM recent_failures;
    \"
  "
  
  shellout.command("bash -c '" <> script <> "' 2>/dev/null")
}

fn get_postgres_db_info() -> Result(String, String) {
  // Use a shell script to execute multiple SQL queries for comprehensive database information
  let script = "
    echo 'PostgreSQL Connection Info:'
    psql -h localhost -U postgres -c \"
      SELECT
        current_database() AS current_db,
        current_user AS username,
        inet_server_addr() AS server_ip,
        inet_server_port() AS server_port,
        pg_backend_pid() AS backend_pid;
    \"
    
    echo '\\nDatabases Overview:'
    psql -h localhost -U postgres -c \"
      SELECT
        datname AS database,
        pg_size_pretty(pg_database_size(datname)) AS size,
        pg_database_size(datname) AS size_bytes,
        datistemplate AS is_template,
        datallowconn AS allows_connections
      FROM pg_database
      WHERE datname NOT IN ('template0', 'template1')
      ORDER BY pg_database_size(datname) DESC;
    \"
    
    echo '\\nPostgreSQL Server Information:'
    psql -h localhost -U postgres -c \"
      SELECT 
        version() AS version,
        current_setting('max_connections') AS max_connections,
        current_setting('shared_buffers') AS shared_buffers,
        current_setting('listen_addresses') AS listen_addresses,
        current_setting('port') AS port,
        current_setting('data_directory') AS data_directory;
    \"
    
    echo '\\nDatabase Activity:'
    psql -h localhost -U postgres -c \"
      SELECT 
        datname, 
        numbackends AS connections,
        xact_commit AS commits,
        xact_rollback AS rollbacks,
        blks_read,
        blks_hit,
        tup_fetched,
        tup_inserted,
        tup_updated,
        tup_deleted
      FROM pg_stat_database
      WHERE datname NOT IN ('template0', 'template1')
      ORDER BY numbackends DESC;
    \"
    
    echo '\\nRole and User Information:'
    psql -h localhost -U postgres -c \"
      SELECT
        rolname AS role,
        rolsuper AS is_superuser,
        rolcreatedb AS can_create_db,
        rolcreaterole AS can_create_role
      FROM pg_roles
      WHERE rolname NOT LIKE 'pg\\\\_%'
      ORDER BY rolname;
    \"
    
    echo '\\nServer Stats:'
    psql -h localhost -U postgres -c \"
      SELECT
        pg_is_in_recovery() AS in_recovery,
        pg_postmaster_start_time() AS server_start_time,
        date_trunc('second', current_timestamp - pg_postmaster_start_time()) AS uptime;
    \"
  "
  
  shellout.command("bash -c '" <> script <> "' 2>/dev/null")
}

// Global variable to store detailed database information
// This is used to separate basic status check from detailed info
pub var postgres_details = ""

fn check_postgres() -> #(SystemComponent, DependencyStatus) {
  case check_command("psql") {
    Missing -> #(Postgres, Missing)
    Available -> {
      // Try to check if postgres daemon is running
      case shellout.command("ps aux | grep 'postgres' | grep -v grep") {
        // Postgres process is running, now try connecting
        Ok(_) -> {
          case shellout.command("psql -h localhost -U postgres -c '\\l' -t 2>/dev/null") {
            Ok(_) -> {
              // Postgres is available, collect detailed information
              let db_info = case get_postgres_db_info() {
                Ok(info) -> "\n\n=== DATABASE INFORMATION ===\n" <> info
                Error(_) -> "\n\nCould not retrieve database information"
              }
              
              let tables_info = case get_postgres_tables_info() {
                Ok(info) -> "\n\n=== TABLE INFORMATION ===\n" <> info
                Error(_) -> "\n\nCould not retrieve table information" 
              }
              
              // Store the detailed information in the global variable
              postgres_details = db_info <> tables_info
              
              // Return Available status
              #(Postgres, Available)
            }
            Error(_) -> #(Postgres, Misconfigured("PostgreSQL daemon is running but connection failed (auth/config issue)"))
          }
        }
        // No postgres process running
        Error(_) -> #(Postgres, Misconfigured("PostgreSQL client installed but server is not running"))
      }
    }
  }
}

fn check_brave_api_key() -> #(SystemComponent, DependencyStatus) {
  case shellout.command("printenv BRAVE_API_KEY") {
    Ok(key) -> {
      case string.trim(key) {
        "" -> #(BraveApiKey, Misconfigured("Environment variable is empty"))
        _ -> #(BraveApiKey, Available)
      }
    }
    Error(_) -> #(BraveApiKey, Missing)
  }
}

fn check_hadolint() -> #(SystemComponent, DependencyStatus) {
  // First check if hadolint is installed natively
  case check_command("hadolint") {
    Available -> #(Hadolint, Available)
    Missing -> {
      // If not found, check if Docker is available as an alternative
      case check_command("docker") {
        Available -> #(
          Hadolint, 
          Misconfigured("Not installed locally, but can use Docker image: docker run --rm -i hadolint/hadolint < Dockerfile")
        )
        Missing -> #(Hadolint, Missing)
      }
    }
  }
}

fn check_pulumi() -> #(SystemComponent, DependencyStatus) {
  case check_command("pulumi") {
    Missing -> #(Pulumi, Missing)
    Available -> {
      // Check pulumi version
      case shellout.command("pulumi version") {
        Ok(version) -> {
          // Parse the version string, expected format "v3.x.x"
          let trimmed = string.trim(version)
          case string.split(trimmed, " ") {
            ["v3." <> _, ..] -> #(Pulumi, Available)
            [version_str, ..] -> #(Pulumi, Misconfigured("Detected version " <> version_str <> ", but v3.x is required"))
            [] -> #(Pulumi, Misconfigured("Could not parse version information"))
          }
        }
        Error(_) -> #(Pulumi, Misconfigured("Failed to get version information"))
      }
    }
  }
}