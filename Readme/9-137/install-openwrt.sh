#!/bin/sh
# TCMinerSystem OpenWrt x86_64 Installer
# Repository: https://github.com/mine-Proxy/TCMinerSystem
# Usage: sh op-x64-install.sh

DEFAULT_VERSION="5.0.1"
OVERSEAS_URL="https://github.com/mine-Proxy/shortcut/raw/refs/heads/main/Readme/9-137/linux/tcstminersystem"
DOMESTIC_URL="https://proxy.tcminersystem.com/id137/tcminersystem"
INSTALL_DIR="/opt/TCMinerSystem"
SERVICE_NAME="tcminersystem"
EXEC_NAME="tcstminersystem"
CONFIG_FILE="${INSTALL_DIR}/rust-config"
DB1="${INSTALL_DIR}/0.d1"
DB2="${INSTALL_DIR}/0.d1-shm"
DB3="${INSTALL_DIR}/0.d1-wal"
LOG_OUT="${INSTALL_DIR}/nohup.out"
LOG_ERR="${INSTALL_DIR}/err.log"

LANG_CHOICE="2"

# ──────────────────────────────────────
# Language selection / 语言选择
# ──────────────────────────────────────
clear
printf "Please select your language / 请选择语言:\n"
printf "1. English\n"
printf "2. 中文\n"
printf "[1-2]: "
read LANG_CHOICE

case "$LANG_CHOICE" in
1)
  # ── English strings ──
  menu_title="---------- TCMinerSystem OpenWrt Installer ----------"
  menu_install="1. Install"
  menu_update="2. Update"
  menu_start="3. Start"
  menu_stop="4. Stop"
  menu_restart="5. Restart"
  menu_autostart="6. Enable auto-start"
  menu_noautostart="7. Disable auto-start"
  menu_status="8. Check status"
  menu_log="9. View error log"
  menu_clearlog="10. Clear logs"
  menu_uninstall="11. Uninstall"
  menu_resetpass="12. Reset password"
  menu_exit="0. Exit"
  prompt_choice="Enter your choice"
  prompt_version="Enter version (default: ${DEFAULT_VERSION})"
  prompt_source="Select download source (1=Overseas/github.com, 2=Domestic/proxy.tcminersystem.com) [1]: "
  err_root="Please run as root!"
  err_platform="This script is only for OpenWrt x86_64"
  err_invalid="Invalid input, cancelling."
  msg_downloading="Downloading..."
  msg_install_ok="Installation completed"
  msg_starting="Starting service"
  msg_already_running="Process is already running"
  msg_start_ok="Service started successfully"
  msg_default_cred="Default account: qzpm19kkx  Default password: xloqslz913"
  msg_start_fail="Failed to start service!"
  msg_stopping="Stopping service"
  msg_stopped="Service stopped"
  msg_autostart_enable="Enabling auto-start"
  msg_autostart_disable="Disabling auto-start"
  msg_uninstall_done="Uninstall completed"
  msg_cleaning_log="Cleaning logs"
  msg_log_cleaned="Logs cleaned"
  msg_reset_pass="Password reset to default"
  msg_config="Config file:"
  msg_waiting_config="Waiting for config file..."
  msg_config_timeout="Config file not detected after 10 seconds"
  msg_process_found="Found running process, stop it first?"
  msg_stop_continue="Enter 1 to stop and continue, 2 to cancel"
  msg_cancelled="Installation cancelled"
  msg_installing="Installing"
  msg_update_done="Update completed"
  ;;
2)
  # ── Chinese strings ──
  menu_title="---------- TCMinerSystem OpenWrt 安装脚本 ----------"
  menu_install="1. 安装"
  menu_update="2. 更新"
  menu_start="3. 启动"
  menu_stop="4. 停止"
  menu_restart="5. 重启"
  menu_autostart="6. 设置开机启动"
  menu_noautostart="7. 关闭开机启动"
  menu_status="8. 查看运行状态"
  menu_log="9. 查看错误日志"
  menu_clearlog="10. 清理日志"
  menu_uninstall="11. 卸载"
  menu_resetpass="12. 重置账号密码"
  menu_exit="0. 退出"
  prompt_choice="请输入选项"
  prompt_version="输入版本号 (默认: ${DEFAULT_VERSION})"
  prompt_source="选择下载源 (1=境外/github.com, 2=境内/proxy.tcminersystem.com) [1]: "
  err_root="请以 root 用户运行此脚本！"
  err_platform="此脚本仅支持 OpenWrt x86_64"
  err_invalid="输入错误，已取消。"
  msg_downloading="正在下载..."
  msg_install_ok="安装完成"
  msg_starting="正在启动服务"
  msg_already_running="程序已在运行中"
  msg_start_ok="服务启动成功"
  msg_default_cred="默认账号: qzpm19kkx  默认密码: xloqslz913"
  msg_start_fail="服务启动失败！"
  msg_stopping="正在停止服务"
  msg_stopped="服务已停止"
  msg_autostart_enable="正在设置开机启动"
  msg_autostart_disable="正在关闭开机启动"
  msg_uninstall_done="卸载完成"
  msg_cleaning_log="正在清理日志"
  msg_log_cleaned="日志已清理"
  msg_reset_pass="密码已重置为默认"
  msg_config="配置文件："
  msg_waiting_config="正在等待配置文件..."
  msg_config_timeout="10秒后配置文件仍未生成"
  msg_process_found="发现正在运行的程序，需要停止后才能继续。"
  msg_stop_continue="输入 1 停止并继续安装，输入 2 取消安装"
  msg_cancelled="已取消安装"
  msg_installing="正在安装"
  msg_update_done="更新完成"
  ;;
*)
  printf "Invalid choice / 无效选择\n"
  exit 1
  ;;
esac

# ──────────────────────────────────────
# Prerequisites check
# ──────────────────────────────────────
[ "$(id -u)" != "0" ] && { printf "%s\n" "$err_root"; exit 1; }

# Check OpenWrt x86_64
if [ "$(uname -m)" != "x86_64" ]; then
  printf "%s\n" "$err_platform"
  exit 1
fi
if [ ! -f /etc/openwrt_release ]; then
  printf "%s\n" "$err_platform"
  exit 1
fi

# ──────────────────────────────────────
# Helper functions
# ──────────────────────────────────────
ensure_cmd() {
  cmd="$1"
  pkg="${2:-$1}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf "Installing %s via opkg...\n" "$pkg"
    opkg update >/dev/null 2>&1
    opkg install "$pkg"
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf "Failed to install %s\n" "$pkg"
      exit 1
    fi
  fi
}

check_process() {
  ps 2>/dev/null | grep -v grep | grep "$1" >/dev/null 2>&1
}

get_config() {
  grep "^${1}=" "$CONFIG_FILE" 2>/dev/null | awk -F= '{print $2}'
}

set_config() {
  key="$1"
  value="$2"
  mkdir -p "$INSTALL_DIR"
  if [ ! -f "$CONFIG_FILE" ]; then
    touch "$CONFIG_FILE"
  fi
  if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
  else
    printf '%s=%s\n' "$key" "$value" >> "$CONFIG_FILE"
  fi
}

# ──────────────────────────────────────
# Service management (procd)
# ──────────────────────────────────────
enable_autostart() {
  printf "%s...\n" "$msg_autostart_enable"
  if [ -f /etc/rc.local ]; then
    if ! grep -q "${INSTALL_DIR}/start.sh" /etc/rc.local 2>/dev/null; then
      sed -i '/^exit 0/i\sh '"${INSTALL_DIR}"'/start.sh >/dev/null 2>&1 &' /etc/rc.local
    fi
  fi
}

disable_autostart() {
  printf "%s...\n" "$msg_autostart_disable"
  if [ -f /etc/rc.local ]; then
    sed -i "\|${INSTALL_DIR}/start.sh|d" /etc/rc.local 2>/dev/null || true
  fi
}

start_svc() {
  printf "%s...\n" "$msg_starting"
  if check_process "$EXEC_NAME"; then
    printf "%s\n" "$msg_already_running"
    return
  fi
  sh "${INSTALL_DIR}/start.sh" > "$LOG_OUT" 2> "$LOG_ERR" &
  sleep 2
  if check_process "$EXEC_NAME"; then
    enable_autostart
    printf "%s\n" "$msg_start_ok"
    printf "%s\n" "$msg_default_cred"
  else
    printf "%s\n" "$msg_start_fail"
  fi
}

stop_svc() {
  printf "%s...\n" "$msg_stopping"
  killall "$EXEC_NAME" 2>/dev/null || true
  sleep 1
  printf "%s\n" "$msg_stopped"
}

restart_svc() {
  stop_svc
  start_svc
}

# ──────────────────────────────────────
# Core functions
# ──────────────────────────────────────
wait_for_config() {
  printf "%s\n" "$msg_waiting_config"
  i=0
  while [ $i -lt 10 ]; do
    if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
      printf "%s %s\n" "$msg_config" "$CONFIG_FILE"
      cat "$CONFIG_FILE"
      return
    fi
    sleep 1
    i=$((i + 1))
  done
  printf "%s\n" "$msg_config_timeout"
}
installapp() {
  printf "%s\n" "$msg_installing"

  # Read version
  printf "%s [%s]: " "$prompt_version" "$DEFAULT_VERSION"
  read input_version
  version="${input_version:-$DEFAULT_VERSION}"

  # Read download source
  printf "%s" "$prompt_source"
  read input_source

  case "$input_source" in
    2) url="${DOMESTIC_URL}-${version}" ;;
    *) url="${OVERSEAS_URL}-${version}" ;;
  esac

  # Check running process
  if check_process "$EXEC_NAME"; then
    printf "%s\n" "$msg_process_found"
    printf "%s\n" "$msg_stop_continue"
    printf "[1-2]: "
    read choice
    case "$choice" in
      1) stop_svc ;;
      *) printf "%s\n" "$msg_cancelled"; return ;;
    esac
  fi

  # Create install directory
  mkdir -p "$INSTALL_DIR"

  # Create log files
  touch "$LOG_OUT" "$LOG_ERR" 2>/dev/null || true

  # Download binary to /tmp first (tmpfs, avoids overlay write issues)
  ensure_cmd curl
  printf "%s %s\n" "$msg_downloading" "$EXEC_NAME"
  curl -fsSL -o /tmp/tcstminersystem.tmp "$url" || {
    printf "Download failed from: %s\n" "$url"
    rm -f /tmp/tcstminersystem.tmp
    exit 1
  }
  cp /tmp/tcstminersystem.tmp "${INSTALL_DIR}/${EXEC_NAME}"
  rm -f /tmp/tcstminersystem.tmp
  chmod +x "${INSTALL_DIR}/${EXEC_NAME}"

  # Create wrapper script for working directory
  cat > "${INSTALL_DIR}/start.sh" << SHWRAP
#!/bin/sh
cd "$INSTALL_DIR"
exec "$INSTALL_DIR/$EXEC_NAME" "\$@"
SHWRAP
  chmod +x "${INSTALL_DIR}/start.sh"

  # Store version (program will auto-create rest of config)
  set_config "VERSION" "$version"

  printf "%s\n" "$msg_install_ok"
  start_svc
  wait_for_config
}

updateapp() {
  current_ver=$(get_config "VERSION")
  [ -z "$current_ver" ] && current_ver="$DEFAULT_VERSION"

  printf "%s (%s) [%s]: " "$prompt_version" "$current_ver" "$current_ver"
  read input_version
  version="${input_version:-$current_ver}"

  printf "%s" "$prompt_source"
  read input_source

  case "$input_source" in
    2) url="${DOMESTIC_URL}-${version}" ;;
    *) url="${OVERSEAS_URL}-${version}" ;;
  esac

  stop_svc

  ensure_cmd curl
  printf "%s %s\n" "$msg_downloading" "$EXEC_NAME"
  curl -fsSL -o /tmp/tcstminersystem.tmp "$url" || {
    printf "Download failed from: %s\n" "$url"
    rm -f /tmp/tcstminersystem.tmp
    exit 1
  }
  cp /tmp/tcstminersystem.tmp "${INSTALL_DIR}/${EXEC_NAME}"
  rm -f /tmp/tcstminersystem.tmp
  chmod +x "${INSTALL_DIR}/${EXEC_NAME}"

  cat > "${INSTALL_DIR}/start.sh" << SHWRAP
#!/bin/sh
cd "$INSTALL_DIR"
exec "$INSTALL_DIR/$EXEC_NAME" "\$@"
SHWRAP
  chmod +x "${INSTALL_DIR}/start.sh"

  set_config "VERSION" "$version"

  printf "%s\n" "$msg_update_done"
  start_svc
  wait_for_config
}

uninstall_app() {
  stop_svc
  disable_autostart
  rm -rf "$INSTALL_DIR"
  printf "%s\n" "$msg_uninstall_done"
}

reset_password() {
  stop_svc
  rm -f "$DB1" "$DB2" "$DB3"
  start_svc
  printf "%s\n" "$msg_reset_pass"
}

view_log() {
  if [ -f "$LOG_ERR" ]; then
    tail -f "$LOG_ERR"
  else
    printf "No log file found.\n"
  fi
}

clear_logs() {
  printf "%s...\n" "$msg_cleaning_log"
  : > "$LOG_OUT" 2>/dev/null || true
  : > "$LOG_ERR" 2>/dev/null || true
  printf "%s\n" "$msg_log_cleaned"
}

status() {
  if check_process "$EXEC_NAME"; then
    printf "PID: "
    ps 2>/dev/null | grep -v grep | grep "$EXEC_NAME" | awk '{print $1}'
  else
    printf "%s %s\n" "$EXEC_NAME" "Not running"
  fi
}

# ──────────────────────────────────────
# Menu
# ──────────────────────────────────────
menu() {
  clear
  printf "%s\n" "$menu_title"
  printf "%s\n" "$menu_install"
  printf "%s\n" "$menu_update"
  printf "%s\n" "$menu_start"
  printf "%s\n" "$menu_stop"
  printf "%s\n" "$menu_restart"
  printf "%s\n" "$menu_autostart"
  printf "%s\n" "$menu_noautostart"
  printf "%s\n" "$menu_status"
  printf "%s\n" "$menu_log"
  printf "%s\n" "$menu_clearlog"
  printf "%s\n" "$menu_uninstall"
  printf "%s\n" "$menu_resetpass"
  printf "%s\n" "$menu_exit"
}

menu
printf "%s [0-12]: " "$prompt_choice"
read menu_choice

case "$menu_choice" in
  1) installapp ;;
  2) updateapp ;;
  3) start_svc ;;
  4) stop_svc ;;
  5) restart_svc ;;
  6) enable_autostart ;;
  7) disable_autostart ;;
  8) status ;;
  9) view_log ;;
  10) clear_logs ;;
  11) uninstall_app ;;
  12) reset_password ;;
  0) exit 0 ;;
  *) printf "%s\n" "$err_invalid"; exit 1 ;;
esac
