# NGINX CVE-2026-42945 一键修复脚本

> 自动检测系统发行版，升级 NGINX 至修复版本 (≥1.30.1)，并备份配置、自动回滚。

---

## 漏洞说明

漏洞编号： **CVE-2026-42945**
漏洞名称：NGINX Rift

NGINX 在处理特定的 rewrite 跳转规则时，请求内容长度计算与实际写入不一致，攻击者可构造恶意请求触发内存破坏，导致工作进程崩溃，甚至远程代码执行。

**受影响版本：** 低于 NGINX 1.30.1 / 1.31.0 的所有版本
**修复版本：** NGINX 1.30.1 / 1.31.0 及以上

---

## 特性

- **自动发行版检测** — Ubuntu/Debian / CentOS/RHEL / Fedora
- **版本自动判断** — 已修复则跳过，未修复才触发升级
- **配置自动备份** — 升级前完整备份 `/etc/nginx` 到时间戳目录
- **升级失败自动回滚** — 升级后版本仍低于目标则恢复备份
- **自动配置测试 & 重载** — 升级成功后自动验证并重载

---

## 支持的系统

| 发行版 | 版本 |
|---|---|
| Ubuntu | 18.04 及以上 |
| Debian | 10 及以上 |
| CentOS | 7 及以上 |
| RHEL | 7 及以上 |
| Fedora | 33 及以上 |

---

## 一键安装 & 运行

```bash
curl -fsSL https://raw.githubusercontent.com/yourname/nginx-cve-2026-42945/main/fix_nginx_cve_2026_42945.sh -o /usr/local/bin/fix_nginx_cve.sh
chmod +x /usr/local/bin/fix_nginx_cve.sh
fix_nginx_cve.sh
```

