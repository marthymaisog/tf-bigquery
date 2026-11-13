resource "google_compute_security_policy" "game_security_policy" {
  name        = "game-telemetry-security-policy"
  description = "Protection against DDoS, floods, and bad actors for game ingestion API"

  # Rule 1: Rate Limiting (Throttle IPs sending > 30 requests in 10 seconds)
  rule {
    action   = "throttle"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)" # Correct format for Google Cloud Armor
      rate_limit_threshold {
        count        = 30
        interval_sec = 10
      }
      enforce_on_key = "IP"
    }
    description = "Rate limit per IP address to prevent request flooding"
  }

  # Default Rule: Allow everything else that passes the rate limit
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }
}