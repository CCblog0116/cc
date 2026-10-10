---
title: "Day 16 — Path Traversal"
date: 2026-07-09
tags:
  - daily
  - security
  - english
description: "- Difficulty: ★★★☆☆ Technical / 技术级"
---

- **Date**: 2026-07-23
- **Difficulty**: ★★★☆☆ (Technical / 技术级)
- **Source**: PortSwigger Web Security Academy + OWASP Foundation
- **Link**: https://portswigger.net/web-security/file-path-traversal | https://owasp.org/Top10/A01_2021-Broken_Access_Control/

> **Path traversal** (路径遍历), also known as **directory traversal** (目录遍历), is an **access control** (访问控制) vulnerability that lets an attacker read arbitrary files on the server by manipulating variables that reference files with **"dot-dot-slash"** (`../`) sequences. It is closely related to **Local File Inclusion** (本地文件包含, **LFI**) and appears under **A01:2021 – Broken Access Control** (失效的访问控制) in the OWASP Top 10.

---

## 1. The Core Idea: Files as User Input

Many web applications read files from the server's filesystem based on user input. A typical example is a product image loaded from a URL like this:

```http
GET /loadImage?filename=218.png HTTP/1.1
Host: shop.example.com
```

Behind the scenes, the server constructs a path and returns the file:

```python
# ❌ Vulnerable: user input is pasted directly into the path
file_path = "/var/www/images/" + request.GET['filename']
return open(file_path).read()
```

If the application does not validate `filename`, an attacker can submit:

```http
GET /loadImage?filename=../../../etc/passwd HTTP/1.1
Host: shop.example.com
```

The server resolves the path to `/var/www/images/../../../etc/passwd`, which simplifies to `/etc/passwd`. On Unix-like systems, this exposes the system's user list. On Windows, the equivalent might target `..\..\..\windows\win.ini`.

> 中文简释：路径遍历的本质是"把用户输入直接拼进文件路径"。攻击者用 `../` 向上跳出应用目录，读取系统敏感文件。

---

## 2. A Simple Example: Escaping the Images Folder

Imagine the application stores product images at:

```
/var/www/app/static/images/
```

An attacker sends:

```http
GET /download?file=../../../etc/hosts HTTP/1.1
```

The server builds the path:

```
/var/www/app/static/images/../../../etc/hosts
```

After the filesystem **canonicalizes** (规范化) the path, it becomes:

```
/etc/hosts
```

The server then returns the system's network configuration file. If the application runs as a privileged user — or if the file is world-readable — the attacker succeeds.

> 中文简释：每个 `../` 向上退一级目录。足够多的 `../` 就能把路径从应用目录退到根目录，再进入系统文件。

---

## 3. Common Bypass Techniques

Modern frameworks and **Web Application Firewalls** (Web 应用防火墙, **WAFs**) often block basic `../` sequences, so attackers use variations.

### 3.1 URL Encoding

Browsers and servers may decode `%2e%2e%2f` as `../` at different stages:

```http
GET /loadImage?filename=%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd HTTP/1.1
```

Double encoding (`%252e%252e%252f`) can sometimes defeat a WAF that decodes only once.

### 3.2 Absolute Paths

Some applications strip `../` but forget to check absolute paths:

```http
GET /loadImage?filename=/etc/passwd HTTP/1.1
```

If the server prepends a base directory without checking whether the input already starts with `/`, the path may resolve to `/etc/passwd`.

### 3.3 Nested Traversal Sequences

If the application strips `../` only once, attackers nest the pattern:

```http
GET /loadImage?filename=....//....//....//etc/passwd HTTP/1.1
```

After one strip of `../`, the remaining string still contains another `../`.

### 3.4 Null Byte Truncation (Legacy Systems)

Older PHP versions treated `%00` as a string terminator:

```http
GET /loadImage?filename=../../../etc/passwd%00.png HTTP/1.1
```

The application might see a "safe" `.png` extension, while the underlying filesystem opens `/etc/passwd`. This is largely historical but still worth knowing.

### 3.5 Different Path Separators

On Windows, both `/` and `\` work, and mixed forms may bypass naive filters:

```http
GET /download?file=..\..\..\windows\win.ini HTTP/1.1
```

> 中文简释：真实攻击不会只用 `../`。编码、绝对路径、嵌套序列、空字节截断、反斜杠都是常见绕过 WAF 或过滤的手法。

---

## 4. What Attackers Usually Target

| Target File | Why It Matters |
|-------------|----------------|
| `/etc/passwd` | Lists Unix user accounts, often proves traversal works |
| `/etc/shadow` | Contains password hashes, normally root-readable only |
| `C:\Windows\win.ini` | Classic Windows proof-of-traversal file |
| Application **configuration files** (配置文件) | May contain database credentials, API keys, or secrets |
| `web.config` / `.env` / `application.yml` | Common locations for leaked credentials |
| Log files | May leak session tokens or internal paths |
| Source code files | Helps attackers find more vulnerabilities |

Path traversal can also lead to **Remote Code Execution** (远程代码执行, **RCE**) if the attacker can write files — for example, by uploading a malicious file to a predictable location and then traversing to execute it.

> 中文简释：攻击者首先读 `/etc/passwd` 验证漏洞，然后尝试读取配置文件、日志或源码。如果能写文件，还可能升级为 RCE。

---

## 5. Prevention: Canonicalize, Then Validate

The only reliable defense is to treat file access as a security boundary and validate paths after the filesystem has resolved them.

### 5.1 Use Canonical Absolute Paths

Resolve the path first, then check whether it still lies inside the allowed directory:

```python
import os

base_dir = "/var/www/app/static/images"
user_input = request.GET['filename']

# Resolve any ../ sequences and symlinks
full_path = os.path.realpath(os.path.join(base_dir, user_input))

if not full_path.startswith(os.path.realpath(base_dir) + os.sep):
    raise PermissionError("Path escapes allowed directory")

return open(full_path).read()
```

`realpath()` resolves symbolic links and `..` sequences, so the final comparison is trustworthy.

### 5.2 Prefer Allowlists Over Blocklists

Instead of blocking `../`, use an **allowlist** (白名单) of permitted filenames:

```python
allowed_files = {"218.png", "219.png", "220.png"}
filename = request.GET['filename']

if filename not in allowed_files:
    raise ValueError("Invalid filename")

return open(os.path.join(base_dir, filename)).read()
```

Blocklists are fragile because attackers constantly find new encodings and bypasses.

### 5.3 Use Indirect Object References

Instead of exposing real filenames, map user-facing identifiers to internal files:

```python
file_map = {
    "img-1": "218.png",
    "img-2": "219.png",
}
internal_name = file_map.get(request.GET['id'])
```

This is the same **Indirect Reference Map** (间接引用映射) technique used to prevent IDOR.

### 5.4 Avoid User-Supplied File Paths Altogether

The safest design is to store files in a database or object storage (like **Amazon S3** or a **CDN**) and return them through an ID that maps to a stored object, not a filesystem path.

### 5.5 Run with Least Privilege

Even if traversal occurs, the application process should not run as root or administrator. The **least privilege** (最小权限) principle limits what files the attacker can actually read.

> 中文简释：防路径遍历的核心是"先规范化路径，再校验是否在允许目录内"。白名单比黑名单可靠，间接引用比真实文件名安全，最小权限能限制突破后的损失。

---

## 6. Path Traversal vs. LFI vs. IDOR

These vulnerabilities overlap but have different focuses:

| Vulnerability | Core Mechanism | Typical Input |
|---------------|----------------|---------------|
| **Path Traversal** (路径遍历) | Escape a directory using `../` or equivalents | File path with traversal sequences |
| **LFI** (Local File Inclusion / 本地文件包含) | Include a local file into application execution | Often PHP `include()` with user input |
| **RFI** (Remote File Inclusion / 远程文件包含) | Include a file from a remote URL | `http://attacker.com/shell.txt` |
| **IDOR** (不安全的直接对象引用) | Access a resource by changing its identifier | Numeric ID, UUID, filename |

A single request can combine multiple issues. For example, `GET /download?file=../../reports/8821.pdf` is both IDOR (the `file` parameter identifies a resource) and path traversal (it escapes the intended directory).

> 中文简释：路径遍历强调"跳出目录"，LFI 强调"把本地文件包含进执行流"，IDOR 强调"改标识符越权"。实际漏洞常常混在一起。

---

## Key Terms

| English | 中文 | Note |
|--------|------|------|
| Path Traversal / Directory Traversal | 路径遍历 / 目录遍历 | 通过 `../` 等序列访问目录外文件 |
| Dot-Dot-Slash (`../`) | 点点斜杠 | 最常用的目录跳出序列 |
| Canonicalization | 规范化 | 解析 `..`、符号链接后得到真实绝对路径 |
| Local File Inclusion (LFI) | 本地文件包含 | 将服务器本地文件包含进应用执行 |
| Remote File Inclusion (RFI) | 远程文件包含 | 从远程 URL 包含文件，危害更大 |
| Access Control | 访问控制 | 决定谁能访问什么资源的机制 |
| Web Application Firewall (WAF) | Web 应用防火墙 | 对编码绕过后的遍历可能失效 |
| Allowlist | 白名单 | 仅允许明确列出的值 |
| Blocklist | 黑名单 | 禁止已知危险模式，易被绕过 |
| Indirect Reference Map | 间接引用映射 | 用户可见 ID 映射到内部真实标识 |
| Least Privilege | 最小权限 | 进程只拥有完成工作所需的最小权限 |
| Remote Code Execution (RCE) | 远程代码执行 | 攻击者在服务器上执行任意代码 |
| Configuration File | 配置文件 | 常含数据库密码、API 密钥等敏感信息 |
| URL Encoding | URL 编码 | 如 `%2f` 表示 `/`，常用于绕过过滤 |
| Null Byte (`%00`) | 空字节 | 旧版 PHP 等语言的字符串终止符 |

---

## 甲方视角思考

- 先规范化再校验：`realpath()` 或等价函数必须在访问文件前调用，直接字符串匹配 `../` 等于给攻击者出题。
- 白名单优于黑名单：尤其在静态资源下载场景，允许的文件名列表比过滤规则更稳。
- 文件服务解耦：核心应用别直接拼接路径读文件，用对象存储 ID 或数据库 BLOB 能减少攻击面。
- 容器与运行权限：以 root 跑应用会让一次路径遍历直接读到 `/etc/shadow`，最小权限是最后一道保险。

---

## 明日预告

**Day 17: Security Misconfiguration — When Defaults Bite Back**  
明天我们继续技术级话题，学习安全错误配置：从默认口令、未删除的示例页面到暴露的调试接口，为什么"开箱即用"常常等于"开箱即危"。
