#!/usr/bin/env bash
# ::
# :: php_audit.sh - Audit PHP shared hosting configuration and permissions
# ::
# :: Usage: sudo ./php_audit.sh [DOCROOT_PATH]
# ::
# :: Provide a path to your web document root (e.g. /home/user/public_html).
# :: The script checks:
# ::   1. PHP running UID/GID and group memberships
# ::   2. PHP configuration settings (open_basedir, allow_url_fopen, allow_url_include, disable_functions, disable_classes, error reporting, session config)
# ::   3. Available PHP stream wrappers
# ::   4. File and directory permissions under docroot
# ::   5. World-readable files under /tmp and docroot
# ::   6. Unix sockets (e.g., mysql.sock) and their perms
# ::   7. Attempt wrapper-based file reads (php://filter, phar://)
# ::   8. umask and default file creation mask
# ::   9. Common sensitive files/directories (e.g., .git, .env, CMS configs)
# ::  10. Presence of common web shells
# ::  11. Symlink vulnerabilities
# ::  12. Outbound connectivity (basic test)
# ::  13. Basic checks for disabled functions bypasses (e.g., via mail(), imagick)
# ::  14. Active localhost connections and listening services
# ::  15. Outbound port accessibility
# ::
# :: Ensure you run as root or a user with sufficient permissions for full checks.
# ::

DOCROOT=${1:-.}

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

function header() {
  echo -e "\n${YELLOW}==> $*${NC}\n"
}

function check_php_identity() {
  header "PHP Effective User/Group and Membership"
  php_user=$(php -r 'echo posix_getpwuid(posix_geteuid())["name"];' 2>/dev/null)
  php_gid=$(php -r 'echo posix_getgrgid(posix_getegid())["name"];' 2>/dev/null)

  if [[ -n "$php_user" && -n "$php_gid" ]]; then
    echo -e "PHP runs as: ${GREEN}$php_user${NC}:${GREEN}$php_gid${NC}"
    echo -e "Groups: $(id -Gn $php_user 2>/dev/null)"
  else
    echo -e "${RED}Could not determine PHP user/group. PHP might not be installed or accessible.${NC}"
  fi
}

function check_php_ini() {
  header "Important PHP ini Settings"
  for setting in open_basedir allow_url_fopen allow_url_include disable_functions disable_classes display_errors log_errors error_reporting; do
    value=$(php -r "echo ini_get('$setting');" 2>/dev/null)
    if [[ -n "$value" ]]; then
      echo -e "$setting = ${GREEN}${value:-<empty>}${NC}"
      # Add specific recommendations/warnings for sensitive settings
      if [[ "$setting" == "display_errors" && "$value" == "1" ]]; then
        echo -e "${RED}  WARNING: display_errors is ON. This can leak sensitive information in production!${NC}"
      fi
      if [[ "$setting" == "log_errors" && "$value" == "0" ]]; then
        echo -e "${YELLOW}  NOTE: log_errors is OFF. Errors are not being logged, hindering debugging and security monitoring.${NC}"
      fi
      if [[ "$setting" == "allow_url_fopen" && "$value" == "1" ]]; then
        echo -e "${YELLOW}  NOTE: allow_url_fopen is ON. While often necessary for web apps, it increases risk for RFI/SSRF if input is not properly validated.${NC}"
      fi
      if [[ "$setting" == "allow_url_include" && "$value" == "1" ]]; then
        echo -e "${RED}  CRITICAL: allow_url_include is ON. This is extremely dangerous and allows arbitrary code execution via remote files.${NC}"
      fi
    else
      echo -e "$setting = ${RED}Could not retrieve (PHP error or setting not found)${NC}"
    fi
  done
}

function check_php_session_config() {
    header "PHP Session Configuration"
    session_settings=(
        "session.save_handler"
        "session.save_path"
        "session.use_cookies"
        "session.use_only_cookies"
        "session.use_strict_mode"
        "session.cookie_httponly"
        "session.cookie_secure"
        "session.cookie_lifetime"
        "session.name"
        "session.gc_probability"
        "session.gc_divisor"
        "session.gc_maxlifetime"
    )

    for setting in "${session_settings[@]}"; do
        value=$(php -r "echo ini_get('$setting');" 2>/dev/null)
        if [[ -n "$value" ]]; then
            echo -e "$setting = ${GREEN}${value:-<empty>}${NC}"
            case "$setting" in
                "session.save_path")
                    if [[ -d "$value" ]]; then
                        perms=$(stat -c "%a %U:%G" "$value" 2>/dev/null)
                        echo -e "  Path permissions: ${BLUE}$perms${NC}"
                        if [[ $(stat -c "%a" "$value") =~ [0-7][0-7][0-7][0-7] && $(stat -c "%a" "$value") -gt 700 ]]; then # Check for broader permissions than 700
                            echo -e "${RED}  WARNING: session.save_path ($value) has broad permissions! Should ideally be 0700 or less if writable only by PHP user.${NC}"
                        fi
                    else
                        echo -e "${YELLOW}  WARNING: session.save_path ($value) does not exist or is not accessible.${NC}"
                    fi
                    ;;
                "session.use_strict_mode")
                    if [[ "$value" == "0" ]]; then
                        echo -e "${RED}  WARNING: session.use_strict_mode is OFF. Session fixation vulnerability possible.${NC}"
                    fi
                    ;;
                "session.cookie_httponly")
                    if [[ "$value" == "0" ]]; then
                        echo -e "${RED}  WARNING: session.cookie_httponly is OFF. Makes session cookies vulnerable to XSS attacks.${NC}"
                    fi
                    ;;
                "session.cookie_secure")
                    if [[ "$value" == "0" ]]; then
                        echo -e "${RED}  WARNING: session.cookie_secure is OFF. Cookies might be sent over unencrypted HTTP, risking interception.${NC}"
                    fi
                    ;;
            esac
        else
            echo -e "$setting = ${RED}Could not retrieve (PHP error or setting not found)${NC}"
        fi
    done
}


function list_stream_wrappers() {
  header "Available PHP Stream Wrappers"
  php -r 'print_r(stream_get_wrappers());' 2>/dev/null | sed 's/^/  /'
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Could not list PHP stream wrappers. PHP might not be installed or accessible.${NC}"
  fi
}

function check_umask() {
  header "Current umask"
  um=$(umask)
  echo -e "umask = ${GREEN}$um${NC}"
}

function scan_permissions() {
  header "Permissions under DOCROOT ($DOCROOT)"
  echo -e "${BLUE}Top 20 world-readable files:${NC}"
  find "$DOCROOT" -xdev -type f -perm -o=r -printf '%M %u:%g %p\n' 2>/dev/null | head -n20
  echo

  echo -e "${BLUE}Top 20 world-writable dirs:${NC}"
  find "$DOCROOT" -xdev -type d -perm -o=w -printf '%M %u:%g %p\n' 2>/dev/null | head -n20
  echo

  echo -e "${BLUE}Files with SUID/SGID bits set (potential privilege escalation):${NC}"
  find "$DOCROOT" -xdev -type f \( -perm -4000 -o -perm -2000 \) -printf '%M %u:%g %p\n' 2>/dev/null
}

function scan_tmp_and_sockets() {
  header "World-readable files in /tmp"
  find /tmp -xdev -type f -perm -o=r -printf '%M %u:%g %p\n' 2>/dev/null | head -n20

  header "Unix sockets under /tmp"
  find /tmp -xdev -type s -printf '%M %u:%g %p\n' 2>/dev/null
}

function test_wrapper_bypass() {
  header "Test php://filter Wrapper Bypass"
  target="/etc/passwd"
  result=$(php -r "\$s = @file_get_contents('php://filter/read=convert.base64-encode/resource=$target'); echo \$s? 'SUCCESS':'FAIL';" 2>/dev/null)
  echo "Access /etc/passwd via filter: ${result}"
  if [[ "$result" == "SUCCESS" ]]; then
    echo -e "${RED}  Potential information disclosure! If PHP can read this, other sensitive files might be readable.${NC}"
  fi
}

function test_phar_bypass() {
  header "Test phar:// Wrapper Bypass"
  target="/etc/passwd"
  result=$(php -r "\$s = @file_get_contents('phar://$target'); echo \$s? 'SUCCESS':'FAIL';" 2>/dev/null)
  echo "Access /etc/passwd via phar://: ${result}"
  if [[ "$result" == "SUCCESS" ]]; then
    echo -e "${RED}  Potential deserialization vulnerability! This can lead to remote code execution.${NC}"
  elif php -r "echo in_array('phar', stream_get_wrappers());" 2>/dev/null | grep -q "1"; then
    echo -e "${YELLOW}  Phar wrapper is available but access failed. This could be due to open_basedir or other restrictions.${NC}"
  else
    echo -e "${BLUE}  Phar wrapper does not appear to be supported or enabled.${NC}"
  fi
}

function check_sensitive_files() {
  header "Checking for Common Sensitive Files/Directories (CMS/Framework Specific)"
  sensitive_patterns=(
    ".git" ".env"                          # General
    "wp-config.php" "*.sql"                # WordPress & DB dumps
    "configuration.php"                    # Joomla
    "settings.php"                         # Drupal
    "config.inc.php"                       # phpMyAdmin, general configs
    "app/etc/local.xml"                    # Magento 1
    "app/etc/env.php"                      # Magento 2
    "web.config"                           # IIS/ASP.NET specific
    "*.bak" "*.zip" "*.tar" "*.tgz" "*.rar" # Backup files
    "uploads/"                             # Common upload directories
    "cache/" "temp/"                       # Common cache/temp directories
    "vendor/"                              # Composer dependencies
    "node_modules/"                        # Node.js dependencies
  )

  for pattern in "${sensitive_patterns[@]}"; do
    echo -e "${BLUE}Searching for '$pattern':${NC}"
    # Use grep -q . to check if find returns any results before printing "Not found."
    if find "$DOCROOT" -xdev -name "$pattern" -print -quit 2>/dev/null | grep -q .; then
      find "$DOCROOT" -xdev -name "$pattern" -printf '%M %u:%g %p\n' 2>/dev/null | head -n 5
    else
      echo "  Not found."
    fi
  done
}

function check_webshells() {
  header "Checking for Common Web Shells (Basic Signature Scan)"
  webshell_patterns=(
    "r57.php"
    "c99.php"
    "shell.php"
    "cmd.php"
    "backdoor.php"
    "mini.php"
    "wso.php"
    "s.php"           # common short names
    "up.php"          # uploaders
    "wp-content/themes/*/404.php" # common injected location for WP
    "wp-includes/pomo/wp-pomo.php" # another common injected location for WP
    "license.txt.bak" # common obfuscation
    "eval.php"        # Generic eval-based shells
    "index.php.bak"   # Backups of core files
    "wp-admin/css/colors/blue/blue.php" # Known WP shell location
  )

  echo "Note: This is a very basic signature scan and can miss many obfuscated or custom shells."
  for pattern in "${webshell_patterns[@]}"; do
    echo -e "${BLUE}Searching for '$pattern':${NC}"
    if find "$DOCROOT" -xdev -type f -name "$pattern" -print -quit 2>/dev/null | grep -q .; then
      find "$DOCROOT" -xdev -type f -name "$pattern" -printf '%M %u:%g %p\n' 2>/dev/null
    else
      echo "  Not found."
    fi
  done
}

function check_symlinks() {
  header "Checking for Dangerous Symlinks"
  echo -e "${BLUE}Symlinks pointing outside DOCROOT:${NC}"
  find "$DOCROOT" -xdev -type l -print0 2>/dev/null | while IFS= read -r -d $'\0' link; do
    target=$(readlink "$link")
    if [[ "$target" != /* ]]; then # Relative path, make it absolute for comparison
      target="$(dirname "$link")/$target"
    fi
    # Resolve DOCROOT to its canonical path to handle symlinks in DOCROOT itself
    canonical_docroot=$(readlink -f "$DOCROOT" 2>/dev/null)
    if [[ -z "$canonical_docroot" ]]; then
      canonical_docroot="$DOCROOT" # Fallback if readlink -f fails
    fi

    # Check if the target path is outside the canonical document root
    if [[ ! "$target" =~ ^"$canonical_docroot"(/.*)?$ ]]; then
      echo -e "${RED}  Symlink: $link -> $target${NC}"
    fi
  done
}

function test_outbound_connectivity() {
  header "Testing Outbound Connectivity (Basic)"
  echo "Attempting to connect to example.com on port 80 using PHP fsockopen..."
  result=$(php -r "\$fp = @fsockopen('example.com', 80, \$errno, \$errstr, 5); if (\$fp) { fclose(\$fp); echo 'SUCCESS'; } else { echo 'FAIL: ' . \$errstr; }" 2>/dev/null)
  echo "Result: ${result}"
  if [[ "$result" == "SUCCESS" ]]; then
    echo -e "${GREEN}  Outbound connection to example.com appears to be possible.${NC}"
  else
    echo -e "${YELLOW}  Outbound connection failed. This could be due to firewall, PHP configuration (e.g., disabled functions), or network issues.${NC}"
  fi

  echo "Attempting DNS resolution for google.com using PHP gethostbyname..."
  result=$(php -r "\$ip = @gethostbyname('google.com'); echo (\$ip && \$ip != 'google.com') ? 'SUCCESS (' . \$ip . ')' : 'FAIL';" 2>/dev/null)
  echo "Result: ${result}"
  if [[ "$result" =~ "SUCCESS" ]]; then
    echo -e "${GREEN}  DNS resolution appears to be working.${NC}"
  else
    echo -e "${YELLOW}  DNS resolution failed. This could indicate a problem with PHP's ability to perform network lookups or a restricted environment.${NC}"
  fi
}

function check_disabled_functions_bypasses() {
  header "Testing Common Disabled Functions Bypass Techniques"
  disabled_functions=$(php -r "echo ini_get('disable_functions');" 2>/dev/null | tr ',' ' ' | xargs -n1 echo | grep -v '^$' | sort -u)

  echo "PHP's 'disable_functions': ${BLUE}${disabled_functions:-<empty>}${NC}"

  # Test 1: mail() function for command execution (if not disabled)
  if echo "$disabled_functions" | grep -qv "mail"; then
    echo -e "${BLUE}Testing mail() for potential command execution (requires sendmail_path/PATH misconfig)...${NC}"
    # This is a very basic attempt and won't always work.
    # A successful bypass would involve capturing output which mail() doesn't directly provide.
    # The PHP code here just attempts to trigger a command.
    mail_result=$(php -r '
      $to = "test@example.com";
      $subject = "test";
      $message = "test";
      $headers = "From: test@example.com";
      $command = "/bin/ls -la / > /tmp/php_ls_output.txt 2>&1"; // Attempt to write output to /tmp
      if (@mail($to, $subject, $message, $headers, "-f $command")) {
          echo "Possible (check /tmp/php_ls_output.txt)";
      } else {
          echo "Failed or mail() disabled/misconfigured.";
      }
    ' 2>/dev/null)
    echo "  Mail() test result: ${mail_result}"
    if [[ "$mail_result" =~ "Possible" ]]; then
        echo -e "${RED}  WARNING: mail() might be used for command execution! Check /tmp/php_ls_output.txt.${NC}"
    fi
  else
    echo -e "${BLUE}mail() is disabled, skipping related bypass test.${NC}"
  fi

  # Test 2: Imagick delegate command injection (if Imagick is installed and not disabled)
  # This is highly dependent on Imagick being present and misconfigured,
  # and specific PHP versions. It's more of a conceptual check.
  if php -m 2>/dev/null | grep -q "imagick" && echo "$disabled_functions" | grep -qv "exec" && echo "$disabled_functions" | grep -qv "shell_exec"; then
    echo -e "${BLUE}Testing Imagick delegate command injection (if Imagick extension is present)...${NC}"

    imagick_result="$(cat <<'EOF_PHP_IMAGICK'
        if (class_exists("Imagick")) {
            $imagick = new Imagick();
            try {
                # This payload attempts to trigger command execution on Imagick's delegate
                # Note: This is highly dependent on Imagick versions and delegates.
                # This is a simplified, non-exploitable test. A real one involves specific XML/SVG attacks.
                $imagick->readImageBlob("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<svg width=\"1\" height=\"1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">
<image xlink:href=\"\"/>
</svg>");
                echo "Imagick present, no direct command execution detected from this simple test.";
            } catch (ImagickException $e) {
                // If it fails with a specific error indicating command attempt, it's interesting
                if (strpos($e->getMessage(), "failed to execute command")) {
                    echo "Possible Imagick delegate injection. Error: " . $e->getMessage();
                } else {
                    echo "Imagick present, but test failed: " . $e->getMessage();
                }
            }
        } else {
            echo "Imagick extension not found.";
        }

EOF_PHP_IMAGICK
      )" 2>/dev/null 

    echo "  Imagick test result: ${imagick_result}"
    if [[ "$imagick_result" =~ "Possible Imagick delegate injection" ]]; then
      echo -e "${RED}  CRITICAL: Imagick delegate command injection might be possible!${NC}"
    fi
  else
    echo -e "${BLUE}Imagick extension not found or relevant functions disabled, skipping related bypass test.${NC}"
  fi

  echo -e "${YELLOW}  Note: Disabled functions bypasses are complex and often rely on specific PHP versions, server configurations, or additional libraries. This script provides basic checks.${NC}"
}

function check_active_localhost_connections() {
    header "Active Localhost Connections and Listening Services"

    # Attempt using netstat or ss first (preferred if available)
    echo -e "${BLUE}Attempting to use netstat/ss to list connections (requires appropriate permissions)...${NC}"
    netstat_output=$( (netstat -tulnp 2>/dev/null || ss -tulnp 2>/dev/null) | grep -E '127.0.0.1|localhost|::1' )

    if [[ -n "$netstat_output" ]]; then
        echo -e "${GREEN}  Found local connections/listeners via netstat/ss:${NC}"
        echo "$netstat_output" | sed 's/^/    /'
    else
        echo -e "${YELLOW}  netstat/ss not found or permission denied. Falling back to PHP probes.${NC}"
        echo -e "${BLUE}Probing common localhost ports via PHP fsockopen:${NC}"

        declare -A common_local_ports=(
            [MySQL]=3306
            [PostgreSQL]=5432
            [Redis]=6379
            [Memcached]=11211
            [Apache_HTTP]=80
            [Apache_HTTPS]=443
            [Nginx_HTTP]=8080
            [Nginx_HTTPS]=8443
        )

        for service in "${!common_local_ports[@]}"; do
            port=${common_local_ports[$service]}
            php_code="
                \$fp = @fsockopen('127.0.0.1', $port, \$errno, \$errstr, 1);
                if (\$fp) {
                    echo 'SUCCESS';
                    fclose(\$fp);
                } else {
                    echo 'FAIL';
                }
            "
            probe_result=$(php -r "$php_code" 2>/dev/null)
            if [[ "$probe_result" == "SUCCESS" ]]; then
                echo -e "  ${GREEN}Service: $service on 127.0.0.1:$port - LISTENING${NC}"
            else
                echo -e "  ${YELLOW}Service: $service on 127.0.0.1:$port - Not Listening or Blocked${NC}"
            fi
        done
        echo -e "${YELLOW}  Note: PHP fsockopen only checks if a port is listening, not active connections.${NC}"
    fi
}

function check_outbound_port_accessibility() {
    header "Outbound Port Accessibility (via PHP fsockopen)"
    echo "This checks if PHP can connect to common outbound ports on public internet hosts."

    declare -A common_outbound_ports=(
        [HTTP]=80
        [HTTPS]=443
        [SMTP]=25
        [SMTPS]=465
        [Submission]=587
        [IMAP]=143
        [IMAPS]=993
        [POP3]=110
        [POP3S]=995
        [DNS]=53 # For UDP, but TCP check is still useful
    )

    remote_host="google.com" # A generally reliable host for testing

    for service in "${!common_outbound_ports[@]}"; do
        port=${common_outbound_ports[$service]}
        php_code="
            \$fp = @fsockopen('$remote_host', $port, \$errno, \$errstr, 3); # 3 second timeout
            if (\$fp) {
                echo 'SUCCESS';
                fclose(\$fp);
            } else {
                echo 'FAIL: ' . \$errstr;
            }
        "
        probe_result=$(php -r "$php_code" 2>/dev/null)
        if [[ "$probe_result" =~ "SUCCESS" ]]; then
            echo -e "  ${GREEN}Can connect to $service ($remote_host:$port)${NC}"
        else
            echo -e "  ${YELLOW}Cannot connect to $service ($remote_host:$port): ${probe_result#FAIL: }${NC}"
        fi
    done
    echo -e "${YELLOW}  Note: Success means the port is reachable; it does not guarantee a service is functional or misconfigured.${NC}"
}


# Execution
header "Starting PHP Shared Hosting Audit"
check_php_identity
check_php_ini
check_php_session_config
list_stream_wrappers
check_umask
scan_permissions
scan_tmp_and_sockets
check_active_localhost_connections # New Network check
check_outbound_port_accessibility  # New Network check
test_wrapper_bypass
test_phar_bypass
check_sensitive_files
check_webshells
check_symlinks
test_outbound_connectivity # Existing, but now complemented by check_outbound_port_accessibility
check_disabled_functions_bypasses

echo -e "\n${YELLOW}Audit complete. Review above for any misconfigurations and potential vulnerabilities.${NC}\n"
            
