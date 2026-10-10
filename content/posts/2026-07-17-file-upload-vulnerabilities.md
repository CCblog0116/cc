---
title: "Day 24 — File Upload Vulnerabilities"
date: 2026-07-17
tags:
  - daily
  - security
  - english
description: "1. Why File Upload Is Dangerous"
---

**Date:** Backfill (originally Day 24)
**Difficulty:** ★★★☆☆ Technical
**Source:** OWASP — *Unrestricted File Upload* + PortSwigger Web Security Academy — *File upload vulnerabilities*
**Link:** https://owasp.org/www-community/vulnerabilities/Unrestricted_File_Upload / https://portswigger.net/web-security/file-upload

---

## 1. Why File Upload Is Dangerous

**Unrestricted file upload** (任意文件上传) is any flaw that lets an attacker upload files the server should never accept — most critically, files the server will later **execute** (执行) or serve to other users.

The impact depends on what the server does with uploads. A PHP host that stores uploads under the web root and serves them as-is can be fully compromised with a single `shell.php`. 影响严重程度取决于：上传的文件会不会被服务器"当代码执行"，或者被其他用户"当内容访问"。

---

## 2. Attack Patterns

| Attack | How It Works | Example |
|--------|--------------|---------|
| **Web shell upload** (网页木马) | Upload a script the server executes | `shell.php`, `shell.aspx`, `shell.jsp` |
| **Extension bypass** (扩展名绕过) | Alternate extensions or case tricks | `shell.php5`, `shell.phtml`, `shell.PHP` |
| **Double extension** (双重扩展名) | Exploit naive validation | `shell.jpg.php` |
| **Null byte / trailing tricks** (截断技巧) | Legacy parsers stop at `%00` | `shell.php%00.jpg` |
| **Content-Type spoofing** (MIME 伪造) | Client sends image Content-Type but body is a script | `Content-Type: image/png` + PHP payload |
| **Polyglot files** (多态文件) | A valid image that also parses as a script | GIF header + embedded PHP |
| **Malicious upload to users** (恶意文件分发) | Upload malware/HTML for other users to download | XSS via SVG, malware hosting |
| **DoS via size** (超大文件拒绝服务) | No size limit fills the disk | Multi-GB uploads |

---

## 3. Defense in Depth — Layered Validation

No single check is enough. Robust upload handling stacks multiple layers:

1. **Extension allowlist** (扩展名白名单): only permit exactly what the business needs — deny by default. Blacklists (`.php` only) are always bypassed.
2. **Content validation** (内容校验): verify the **magic bytes** (文件头魔数) match the claimed type; for images, re-encode them (this strips embedded payloads).
3. **Rename everything** (随机重命名): never keep the user-supplied filename. Generate a random name + store the original name in the database (prevents path traversal via filename, and hides predictable URLs).
4. **Store outside the web root** (存储在 Web 根目录之外): serve uploads through a controller/API, not the web server directly — the OS will never execute them.
5. **Strip metadata** (清理元数据): remove EXIF and comments that can carry payloads.
6. **Serve safely** (安全下发): set `Content-Disposition: attachment`, correct `Content-Type`, and a restrictive `Content-Security-Policy` on the download endpoint.
7. **Size and rate limits** (大小与频率限制): cap file size, per-user quota, and scan with **AV** (杀毒引擎) asynchronously.

---

## 4. Server Configuration Matters

Even perfect application code can be undone by a permissive web server:

- **Nginx misconfiguration** (Nginx 解析漏洞): `/uploads/image.jpg/.php` executed as PHP if `cgi.fix_pathinfo=1` — set `cgi.fix_pathinfo=0` and disable path-info handling for upload directories.
- **`.htaccess` upload**: on Apache, if users can upload a `.htaccess` file, they can make `.jpg` files execute as PHP — never allow dotfiles in uploads.
- **Directory permissions**: the upload directory needs write but never execute (`chmod` no-exec / web server config deny script handlers).

服务器层面要保证"上传目录只存文件、永远不执行"，这一层比应用代码更可靠。

---

## 5. 甲方视角思考

- 资产扫描重点盯上传点：文件上传接口是 Web 漏扫和红队的首选目标，纳入重点测试范围。
- 服务器配置基线检查：`cgi.fix_pathinfo`、上传目录禁执行、禁 dotfile 上传，应写入等保三级基线加固清单。
- 上传功能上线前做渗透测试：白名单、重命名、目录隔离、下发头四项缺一不可。
- 监控上传目录异常文件：定期比对上传目录的文件类型分布，出现脚本文件立即告警。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Unrestricted file upload | 任意文件上传 | Accepting dangerous file types without validation |
| Web shell | 网页木马 | Uploaded script giving remote command execution |
| Extension allowlist | 扩展名白名单 | Only permit pre-approved file extensions |
| Magic bytes | 文件头魔数 | Fixed header bytes identifying true file type |
| Content-Type spoofing | MIME 类型伪造 | Declaring an innocent type while uploading a script |
| Polyglot file | 多态文件 | A file valid in multiple formats (image + script) |
| Null byte truncation | 空字节截断 | Using `%00` to cut off extensions in legacy parsers |
| Double extension | 双重扩展名 | `file.jpg.php` — bypassing naive checks |
| Path traversal | 路径穿越 | `../` sequences in filenames to escape upload dir |
| Web root | Web 根目录 | Directory the web server serves directly |
| cgi.fix_pathinfo | 路径修复配置 | Nginx+PHP config flaw enabling `/img.jpg/.php` execution |
| Content-Disposition | 内容处置头 | `attachment` forces download instead of inline render |
| EXIF metadata | 可交换图像文件元数据 | Image metadata that can hide payloads |
| Quarantine | 隔离区 | Storage area for suspected malicious uploads |

---

## Tomorrow's Preview

**Day 25 — XML External Entity (XXE) Injection (XML 外部实体注入):** how DTD entities turn XML parsers into file-readers and SSRF machines, and how to disable external entities in Java, Python, and PHP.
