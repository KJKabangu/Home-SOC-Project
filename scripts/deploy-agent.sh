#!/usr/bin/env bash
# =============================================================================
# deploy-agent.sh — Wazuh Agent Deployment & Enrollment
# Home SOC Project | Author: KJ Kabangu
#
# Usage:
#   chmod +x deploy-agent.sh
#   sudo ./deploy-agent.sh --manager <MANAGER_IP> --name <AGENT_NAME> [OPTIONS]
#
# Examples:
#   sudo ./deploy-agent.sh --manager 192.168.1.10 --name raspberrypi-01
#   sudo ./deploy-agent.sh --manager 192.168.1.10 --name windows-vm --group workstations
#   sudo ./deploy-agent.sh --manager 192.168.1.10 --name web-server --group servers --verify
#
# Supported OS: Ubuntu/Debian, CentOS/RHEL/Fedora, Raspberry Pi OS
# Wazuh version: 4.7.x
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Colour output
# -----------------------------------------------------------------------------
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
banner()  { echo -e "\n${BOLD}${CYAN}=== $* ===${RESET}\n"; }

# -----------------------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------------------
MANAGER_IP=""
AGENT_NAME=""
AGENT_GROUP="default"
WAZUH_VERSION="4.7"
VERIFY=false
UNINSTALL=false

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------
usage() {
  cat <<EOF

${BOLD}deploy-agent.sh${RESET} — Enroll this host as a Wazuh agent

${BOLD}USAGE${RESET}
  sudo ./deploy-agent.sh --manager <IP> --name <NAME> [OPTIONS]

${BOLD}REQUIRED${RESET}
  --manager  <IP>     IP address of your Wazuh manager
  --name     <NAME>   Unique agent name (e.g. raspberrypi-01)

${BOLD}OPTIONS${RESET}
  --group    <GROUP>  Agent group (default: "default")
  --verify            Run a connectivity check after enrollment
  --uninstall         Remove the Wazuh agent from this host
  -h, --help          Show this help

EOF
  exit 0
}

# -----------------------------------------------------------------------------
# Argument parsing
# -----------------------------------------------------------------------------
[[ $# -eq 0 ]] && usage

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manager)  MANAGER_IP="$2";    shift 2 ;;
    --name)     AGENT_NAME="$2";    shift 2 ;;
    --group)    AGENT_GROUP="$2";   shift 2 ;;
    --verify)   VERIFY=true;        shift   ;;
    --uninstall) UNINSTALL=true;    shift   ;;
    -h|--help)  usage ;;
    *) error "Unknown option: $1. Run with --help for usage." ;;
  esac
done

# -----------------------------------------------------------------------------
# Pre-flight checks
# -----------------------------------------------------------------------------
preflight() {
  banner "Pre-flight Checks"

  [[ $EUID -ne 0 ]] && error "This script must be run as root (use sudo)."

  if [[ "$UNINSTALL" == false ]]; then
    [[ -z "$MANAGER_IP" ]] && error "--manager is required."
    [[ -z "$AGENT_NAME" ]] && error "--name is required."

    # Validate IP format
    if ! echo "$MANAGER_IP" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
      error "Invalid IP address: $MANAGER_IP"
    fi

    # Check manager reachability
    info "Pinging Wazuh manager at $MANAGER_IP ..."
    if ! ping -c 2 -W 3 "$MANAGER_IP" &>/dev/null; then
      warn "Manager did not respond to ping — continuing anyway (ICMP may be blocked)."
    else
      success "Manager is reachable."
    fi

    # Check port 1514 (agent communication)
    info "Checking port 1514 on manager ..."
    if command -v nc &>/dev/null; then
      if nc -z -w 3 "$MANAGER_IP" 1514 &>/dev/null; then
        success "Port 1514 open."
      else
        warn "Port 1514 not reachable — ensure the firewall allows agent traffic."
      fi
    fi
  fi

  # Detect OS
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS_ID="${ID}"
    OS_NAME="${PRETTY_NAME}"
  else
    error "Cannot detect OS — /etc/os-release not found."
  fi

  info "Detected OS: $OS_NAME"

  case "$OS_ID" in
    ubuntu|debian|raspbian) PKG_MGR="apt" ;;
    centos|rhel|fedora|rocky|almalinux) PKG_MGR="rpm" ;;
    *) error "Unsupported OS: $OS_ID. Supported: Ubuntu, Debian, Raspberry Pi OS, CentOS, RHEL, Fedora." ;;
  esac

  success "Pre-flight complete."
}

# -----------------------------------------------------------------------------
# Uninstall
# -----------------------------------------------------------------------------
uninstall_agent() {
  banner "Uninstalling Wazuh Agent"

  info "Stopping wazuh-agent service ..."
  systemctl stop wazuh-agent 2>/dev/null || true
  systemctl disable wazuh-agent 2>/dev/null || true

  if [[ "$PKG_MGR" == "apt" ]]; then
    apt-get remove --purge -y wazuh-agent
    apt-get autoremove -y
  else
    rpm -e wazuh-agent 2>/dev/null || yum remove -y wazuh-agent
  fi

  # Clean up leftover config
  rm -rf /var/ossec /etc/wazuh-agent 2>/dev/null || true

  success "Wazuh agent removed from this host."
  exit 0
}

# -----------------------------------------------------------------------------
# Install
# -----------------------------------------------------------------------------
install_agent() {
  banner "Installing Wazuh Agent"

  if systemctl is-active --quiet wazuh-agent 2>/dev/null; then
    warn "Wazuh agent is already running on this host."
    read -rp "Reinstall / re-enroll? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
    systemctl stop wazuh-agent
  fi

  if [[ "$PKG_MGR" == "apt" ]]; then
    info "Adding Wazuh apt repository ..."
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor \
      -o /usr/share/keyrings/wazuh.gpg

    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] \
https://packages.wazuh.com/${WAZUH_VERSION}/apt/ stable main" \
      > /etc/apt/sources.list.d/wazuh.list

    apt-get update -qq
    info "Installing wazuh-agent ..."
    WAZUH_MANAGER="$MANAGER_IP" \
    WAZUH_AGENT_NAME="$AGENT_NAME" \
    WAZUH_AGENT_GROUP="$AGENT_GROUP" \
    apt-get install -y wazuh-agent

  else
    info "Adding Wazuh rpm repository ..."
    cat > /etc/yum.repos.d/wazuh.repo <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/${WAZUH_VERSION}/yum/
protect=1
EOF
    info "Installing wazuh-agent ..."
    WAZUH_MANAGER="$MANAGER_IP" \
    WAZUH_AGENT_NAME="$AGENT_NAME" \
    WAZUH_AGENT_GROUP="$AGENT_GROUP" \
    yum install -y wazuh-agent
  fi

  success "Package installed."
}

# -----------------------------------------------------------------------------
# Configure
# -----------------------------------------------------------------------------
configure_agent() {
  banner "Configuring Agent"

  OSSEC_CONF="/var/ossec/etc/ossec.conf"

  [[ ! -f "$OSSEC_CONF" ]] && error "ossec.conf not found at $OSSEC_CONF — installation may have failed."

  info "Writing manager IP to ossec.conf ..."
  sed -i "s|<address>.*</address>|<address>${MANAGER_IP}</address>|g" "$OSSEC_CONF"

  # Enable log collection for common sources
  info "Enabling log collection (auth, syslog, dpkg) ..."
  cat >> "$OSSEC_CONF" <<EOF

  <!-- Added by deploy-agent.sh -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/auth.log</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/dpkg.log</location>
  </localfile>
EOF

  success "Configuration written."
}

# -----------------------------------------------------------------------------
# Enable & start
# -----------------------------------------------------------------------------
start_agent() {
  banner "Starting Wazuh Agent"

  systemctl daemon-reload
  systemctl enable wazuh-agent
  systemctl start wazuh-agent

  sleep 3  # give the service a moment to connect

  if systemctl is-active --quiet wazuh-agent; then
    success "wazuh-agent is running."
  else
    error "wazuh-agent failed to start. Check: journalctl -u wazuh-agent -n 50"
  fi
}

# -----------------------------------------------------------------------------
# Verify enrollment
# -----------------------------------------------------------------------------
verify_enrollment() {
  banner "Verifying Enrollment"

  info "Checking agent status ..."
  /var/ossec/bin/wazuh-control status || true

  info "Agent connection log (last 10 lines):"
  tail -n 10 /var/ossec/logs/ossec.log 2>/dev/null || warn "Log not yet available."

  info "To confirm enrollment on the manager, run:"
  echo -e "  ${CYAN}/var/ossec/bin/agent_control -l${RESET}"
  echo -e "  or check the Wazuh dashboard → Agents"
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
print_summary() {
  banner "Deployment Complete"
  echo -e "  ${BOLD}Agent name:${RESET}    $AGENT_NAME"
  echo -e "  ${BOLD}Manager IP:${RESET}    $MANAGER_IP"
  echo -e "  ${BOLD}Agent group:${RESET}   $AGENT_GROUP"
  echo -e "  ${BOLD}OS:${RESET}            $OS_NAME"
  echo -e ""
  echo -e "  ${BOLD}Useful commands:${RESET}"
  echo -e "  ${CYAN}systemctl status wazuh-agent${RESET}           — check service"
  echo -e "  ${CYAN}tail -f /var/ossec/logs/ossec.log${RESET}      — live agent log"
  echo -e "  ${CYAN}systemctl restart wazuh-agent${RESET}          — restart agent"
  echo -e ""
  success "This host is now reporting to your Home SOC. 🛡️"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  echo -e "\n${BOLD}${CYAN}Wazuh Agent Deployment — Home SOC Project${RESET}\n"

  preflight

  if [[ "$UNINSTALL" == true ]]; then
    uninstall_agent
  fi

  install_agent
  configure_agent
  start_agent

  [[ "$VERIFY" == true ]] && verify_enrollment

  print_summary
}

main "$@"