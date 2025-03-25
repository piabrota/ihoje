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
  ]
  
  let failures = list.filter(all_checks, fn(result) {
    case result {
      #(_, Available) -> False
      _ -> True
    }
  })
  
  case list.length(failures) {
    0 -> {
      io.println("\n✅ All system components are properly configured.")
    }
    _ -> {
      io.println("\n❌ Some system components are missing or misconfigured:")
      list.each(failures, print_dependency_status)
    }
  }
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
  }
  
  case status {
    Available -> io.println("  ✅ " <> component_name <> " is available")
    Missing -> io.println("  ❌ " <> component_name <> " is missing")
    Misconfigured(reason) -> io.println("  ⚠️  " <> component_name <> " is misconfigured: " <> reason)
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

fn check_postgres() -> #(SystemComponent, DependencyStatus) {
  case check_command("psql") {
    Missing -> #(Postgres, Missing)
    Available -> {
      // Try to check if postgres daemon is running
      case shellout.command("ps aux | grep 'postgres' | grep -v grep") {
        // Postgres process is running, now try connecting
        Ok(_) -> {
          case shellout.command("psql -h localhost -U postgres -c '\\l' -t 2>/dev/null") {
            Ok(_) -> #(Postgres, Available)
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