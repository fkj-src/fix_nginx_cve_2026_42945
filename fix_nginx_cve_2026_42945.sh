#!/bin/bash
# fix_nginx_cve_2026_42945.sh
# 自动检测系统并升级 NGINX 到修复版本 (>=1.30.1)
# 适配 Ubuntu/Debian / CentOS/RHEL / Fedora

set -euo pipefail

BACKUP_DIR="/root/nginx_bak_$(date +%Y%m%d_%H%M%S)"
MIN_VERSION="1.30.1"
NGINX_CONF="/etc/nginx"

# --------------- 工具函数 ---------------

log_info()  { echo -e "\033[32m[INFO]\033[0m  $*"; }
log_warn()  { echo -e "\033[33m[WARN]\033[0m  $*"; }
log_err()   { echo -e "\033[31m[ERROR]\033[0m $*" >&2; }

get_nginx_ver() { nginx -v 2>&1 | grep -Po '\d+\.\d+\.\d+'; }

version_ge() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# --------------- 1. 前置检查 ---------------

log_info "检查当前 NGINX 版本..."
CURRENT_VER=$(get_nginx_ver)
log_info "当前版本: $CURRENT_VER"

if version_ge "$CURRENT_VER" "$MIN_VERSION"; then
    log_info "当前版本已修复漏洞（≥$MIN_VERSION），无需升级。"
    exit 0
fi

log_warn "当前版本低于修复版本 $MIN_VERSION，准备升级..."

# 备份配置
log_info "备份 NGINX 配置 → $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -ra "$NGINX_CONF" "$BACKUP_DIR/"

# --------------- 2. 检测发行版 ---------------

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=${ID,,}   # 转小写
    DISTRO_VER=$VERSION_ID
else
    log_err "无法检测系统发行版。"
    exit 1
fi

log_info "检测到系统发行版: $DISTRO $DISTRO_VER"

# --------------- 3. 添加官方源并升级 ---------------

case "$DISTRO" in
    ubuntu|debian)
        log_info "配置 NGINX 官方 apt 源..."
        curl -fsSL https://nginx.org/keys/nginx_signing.key \
            | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg
        CODENAME=$(. /etc/os-release && echo $UBUNTU_CODENAME)
        [ -z "$CODENAME" ] && CODENAME="$DISTRO_VER"
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/$DISTRO $CODENAME nginx" \
            > /etc/apt/sources.list.d/nginx.list
        apt update
        log_info "安装最新 NGINX..."
        apt install --only-upgrade -y nginx
        ;;

    centos|rhel)
        log_info "配置 NGINX 官方 yum 源..."
        yum install -y yum-utils 2>/dev/null || dnf install -y yum-utils 2>/dev/null
        yum-config-manager --add-repo https://nginx.org/packages/centos/$DISTRO_VER/x86_64/ 2>/dev/null || \
        yum-config-manager --add-repo https://nginx.org/packages/rhel/$DISTRO_VER/x86_64/
        yum makecache 2>/dev/null || dnf makecache
        log_info "安装最新 NGINX..."
        yum update -y nginx || dnf update -y nginx
        ;;

    fedora)
        log_info "配置 NGINX 官方 dnf 源..."
        dnf install -y dnf-plugins-core
        dnf config-manager --add-repo https://nginx.org/packages/fedora/$(rpm -E %fedora)/x86_64/
        dnf makecache
        log_info "安装最新 NGINX..."
        dnf update -y nginx
        ;;

    *)
        log_err "暂不支持此发行版: $DISTRO"
        exit 1
        ;;
esac

# --------------- 4. 验证 ---------------

NEW_VER=$(get_nginx_ver)
log_info "升级后版本: $NEW_VER"

if version_ge "$NEW_VER" "$MIN_VERSION"; then
    log_info "✓ 升级成功！版本已修复漏洞。"
    nginx -t && nginx -s reload
    log_info "✓ NGINX 配置测试通过，已重载。"
else
    log_err "升级后版本仍低于 $MIN_VERSION，正在恢复备份配置..."
    cp -ra "$BACKUP_DIR"/* "$NGINX_CONF/"
    nginx -t && nginx -s reload
    log_err "配置已恢复，请手动处理。"
    exit 1
fi

log_info "备份目录: $BACKUP_DIR"
log_info "脚本执行完成。"

