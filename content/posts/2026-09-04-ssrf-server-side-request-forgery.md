---
title: "Day 22 — Server-Side Request Forgery (SSRF): When Your Server Becomes the Attacker's Proxy"
date: 2026-09-04
tags:
  - daily
  - security
  - english
description: "In 2019, Capital One suffered one of the largest cloud breaches in history. A misconfigured Web Application Firewall WAF （Web 应用防火墙） allowed an attack"
---

**Date:** 2026-09-04 | **Difficulty:** ★★★☆☆ Technical | **Source:** OWASP Top 10:2021 A10 / PortSwigger Web Security Academy | **Link:** [OWASP A10:2021](https://owasp.org/Top10/A10_2021-Server-Side_Request_Forgery_%28SSRF%29/), [PortSwigger SSRF](https://portswigger.net/web-security/ssrf)

---

## Why This Matters

In 2019, Capital One suffered one of the largest cloud breaches in history. A misconfigured **Web Application Firewall (WAF)** （Web 应用防火墙） allowed an attacker to abuse an SSRF vulnerability in an internal application. The server was tricked into querying the **AWS metadata service** （AWS 元数据服务） at `http://169.254.169.254/`, stealing temporary **IAM credentials** （身份与访问管理凭证） and exposing data from more than 100 million customers.

SSRF is ranked as **A10 in the OWASP Top 10:2021** for a reason: it turns an ordinary application feature — fetching a URL on behalf of a user — into a powerful **lateral movement** （横向移动） and **privilege escalation** （权限提升） primitive. In cloud-native environments, SSRF is often the bridge between "a small input-validation bug" and "full account takeover."

> SSRF 的凶险之处在于：攻击者不直接访问你的内网，而是让你的服务器代替他去访问。

---

## What Is SSRF?

**Server-Side Request Forgery (SSRF)** （服务器端请求伪造） occurs when an application accepts a user-supplied URL and makes an HTTP request to it from the server side. If the application does not validate or restrict the target address, an attacker can force the server to connect to internal services, cloud metadata endpoints, or other restricted resources.

A typical vulnerable code pattern looks like this in Python:

```python
import requests

def fetch_url(user_url):
    # No validation on user_url — attacker controls the destination
    return requests.get(user_url, timeout=5).text
```

In this example, if the user submits `http://localhost:22/`, the server will try to connect to its own SSH service and may leak banner information. If the server runs inside AWS, submitting `http://169.254.169.254/latest/meta-data/iam/security-credentials/` can return active cloud credentials.

---

## Common Attack Targets in SSRF

Attackers do not use SSRF to "fetch external websites" — they use it to reach places they could never reach directly.

### 1. Cloud Metadata Services

Cloud providers expose a link-local metadata IP to every virtual machine. This address is reachable only from within the instance, making it a perfect SSRF target:

| Cloud Provider | Metadata IP | Sensitive Endpoint |
|---|---|---|
| AWS | `169.254.169.254` | `/latest/meta-data/iam/security-credentials/<role-name>` |
| Azure | `169.254.169.254` | `/metadata/instance/compute?api-version=...` (requires header) |
| GCP | `169.254.169.254` | `/computeMetadata/v1/instance/service-accounts/default/token` |
| Alibaba Cloud | `100.100.100.200` | `/latest/meta-data/ram/security-credentials/<role-name>` |

These endpoints often return **access tokens** （访问令牌）, IAM role credentials, or **instance identity documents** （实例身份凭证） that let the attacker pivot into the cloud control plane.

> 云上实例元数据服务是 SSRF 的"王座"——一旦拿到临时凭证，往往等同于拿到云账号的钥匙。

### 2. Internal Services and APIs

Internal microservices usually trust traffic originating from the local network. SSRF lets the attacker bypass **network segmentation** （网络分段） and interact with APIs that assume "only internal callers can reach me."

Examples include:

- `http://localhost:6379/` — Redis service, possibly without authentication
- `http://127.0.0.1:8080/admin` — internal admin panel with no external exposure
- `http://internal-api.corp/private/users` — service-to-service API endpoints
- `file:///etc/passwd` — in some SSRF gadgets, the request library supports the `file://` scheme

> 很多内部服务默认"内网可信"，SSRF 恰好能伪造出这份信任。

### 3. Port Scanning and Banner Grabbing from the Inside

By observing error messages, response timing, and behavior differences, an attacker can use SSRF as a **port scanner** （端口扫描器） against the internal network. A connection refused error means the port is closed; a slow timeout or an unusual response means an internal service is listening.

This is especially dangerous because the scan originates from a trusted internal server, so perimeter firewalls and IDS will not flag it.

> SSRF 能把你的服务器变成一台合法的内网扫描器，绕过所有边界防护的检测逻辑。

---

## SSRF Variants

### Basic SSRF

The attacker directly controls the full URL, and the server's response is returned to the attacker. This is the easiest to exploit and verify.

### Blind SSRF

The server's response is not returned to the user. The attacker infers success by observing side effects: DNS lookups to an attacker-controlled server, out-of-band HTTP requests, timing differences, or error messages.

**Blind SSRF** （盲 SSRF） is harder to detect and often underestimated, but it can still trigger **Out-of-Band Application Security Testing (OAST)** （带外应用安全测试） payloads and exfiltrate sensitive data through DNS or HTTP callbacks.

### Contextual SSRF

Sometimes the user controls only part of the URL, such as a hostname suffix or a path parameter. Attackers combine **open redirects** （开放重定向）, **URL parsing inconsistencies** （URL 解析不一致性）, and **DNS rebinding** （DNS 重绑定） to bypass partial validation.

---

## Bypass Techniques You Should Know

Modern applications often try to block SSRF with naive filters. Attackers use many tricks to get around them:

| Bypass Method | Example | Why It Works |
|---|---|---|
| IP encoding | `http://0177.0.0.1/` = `127.0.0.1` | Filters may only check dotted-decimal notation |
| DNS to localhost | `http://spoofed.burpcollaborator.net` resolving to `127.0.0.1` | Validation happens at DNS resolution time, not at connection time |
| IPv6 | `http://[::1]/` | Filters may forget to handle IPv6 localhost |
| URL parser confusion | `http://1.1.1.1@127.0.0.1` | Some parsers see the auth part, others the host |
| Redirect | A whitelisted URL that 302-redirects to `169.254.169.254` | Validation occurs before following redirects |
| DNS rebinding | Domain first resolves to public IP, then to `127.0.0.1` | Time-of-check vs time-of-use problem |
| Alternative schemes | `file:///etc/passwd`, `dict://`, `ftp://` | Libraries may support more protocols than expected |

This is why **URL parsing alone is not a defense** — you must also validate the actual destination IP after resolution and before connection.

---

## Defense: What Actually Works

### 1. Network-Level Isolation

The strongest defense is architecture: do not let the server that processes user URLs reach sensitive internal networks.

- Place the URL-fetching service in a dedicated **DMZ** （非军事区，隔离网络） or **sandboxed subnet** （沙箱子网）.
- Use **egress filtering** （出站过滤） to block outbound traffic to private IP ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `127.0.0.0/8`, `169.254.169.254/32`).
- Enforce these rules at the **firewall** （防火墙） or **security group** （安全组） level, not only in code.

> 网络层阻断比代码层校验更可靠，因为代码总可能被绕过，但物理隔离不会。

### 2. Strict URL Parsing and Validation

If you must accept URLs, parse them carefully and reject anything that does not match an **allowlist** （白名单） of hosts, schemes, and ports.

```python
from urllib.parse import urlparse
import socket
import ipaddress

ALLOWED_SCHEMES = {"https", "http"}
DENIED_IPS = {
    ipaddress.ip_network("10.0.0.0/8"),
    ipaddress.ip_network("172.16.0.0/12"),
    ipaddress.ip_network("192.168.0.0/16"),
    ipaddress.ip_network("127.0.0.0/8"),
    ipaddress.ip_network("169.254.169.254/32"),
    ipaddress.ip_network("::1/128"),
    ipaddress.ip_network("fc00::/7"),
    ipaddress.ip_network("fe80::/10"),
}

def is_safe_url(url: str) -> bool:
    parsed = urlparse(url)
    if parsed.scheme not in ALLOWED_SCHEMES:
        return False
    hostname = parsed.hostname
    if not hostname:
        return False
    try:
        ip = ipaddress.ip_address(socket.getaddrinfo(hostname, None)[0][4][0])
    except socket.gaierror:
        return False
    return not any(ip in denied for denied in DENIED_IPS)
```

Key design principles:

- **Resolve first, then check the IP** — to catch DNS rebinding, resolve the hostname and validate the resulting IP immediately before making the connection.
- **Re-resolve on connection** — or even better, pin the validated IP and connect by IP while sending the original Host header.
- **Block link-local and metadata IPs** explicitly, not just RFC1918 ranges.
- **Disable redirects** or re-validate the target after every redirect hop.

> 校验顺序很重要：先解析 DNS，再检查 IP，最后连接。重定向的每一跳都要重新校验。

### 3. Use a Dedicated Library or Wrapper

Do not reinvent URL fetching. Frameworks like `ssrfGuard` or language-specific hardened HTTP clients enforce the checks above consistently.

### 4. Least Privilege in Cloud Roles

Even if SSRF reaches the metadata service, the damage depends on what the leaked role can do. Follow the **principle of least privilege** （最小权限原则）:

- Avoid assigning **instance roles** （实例角色） broad permissions.
- Require **IMDSv2** （Instance Metadata Service version 2） on AWS — it uses session-oriented requests that are harder to exploit via simple GET-based SSRF.
- Rotate credentials frequently and monitor for unusual API calls from instances.

> 云凭证的权限越窄，SSRF 拿到的"钥匙"就越没用。

### 5. Disable Unnecessary URL Schemes and Response Echo

- Restrict the HTTP client to `http` and `https` only; disable `file://`, `dict://`, `gopher://`, `ftp://`.
- In blind-SSRF-prone features, avoid returning raw server responses or detailed error messages to the user.

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Server-Side Request Forgery (SSRF) | 服务器端请求伪造 | 攻击者诱导服务端发起非预期请求的漏洞 |
| Web Application Firewall (WAF) | Web 应用防火墙 | 位于应用前的 HTTP 流量过滤层 |
| AWS Metadata Service | AWS 元数据服务 | 云实例内部访问的元数据接口，IP 为 169.254.169.254 |
| IAM Credentials | IAM 凭证 / 身份与访问管理凭证 | 云身份和权限体系中的凭据 |
| Lateral Movement | 横向移动 | 攻击者从内网一个点扩散到其他系统 |
| Privilege Escalation | 权限提升 | 从低权限获取更高权限的过程 |
| Access Token | 访问令牌 | 用于认证和授权的短期凭证 |
| Instance Identity Document | 实例身份凭证 | 云平台签发的实例身份证明 |
| Network Segmentation | 网络分段 | 按安全级别划分网络区域 |
| Port Scanning | 端口扫描 | 探测目标开放端口的技术 |
| Blind SSRF | 盲 SSRF | 响应不返回给用户，需通过旁路推断 |
| Out-of-Band (OAST) | 带外 | 不依赖应用直接回显的攻击/检测通道 |
| Open Redirect | 开放重定向 | 应用接受任意 URL 参数进行跳转 |
| URL Parsing Inconsistency | URL 解析不一致性 | 不同组件对同一 URL 解析结果不同 |
| DNS Rebinding | DNS 重绑定 | 域名 TTL 到期后解析到不同 IP 的攻击 |
| DMZ | 非军事区 / 隔离区 | 放置对外服务的中立网络区域 |
| Egress Filtering | 出站过滤 | 控制服务器对外发起的网络流量 |
| Security Group | 安全组 | 云环境中的虚拟防火墙规则 |
| Allowlist | 白名单 | 仅允许明确列出的目标 |
| Principle of Least Privilege | 最小权限原则 | 只授予完成任务所需的最小权限 |
| Instance Role | 实例角色 | 附加给云实例的临时身份 |
| IMDSv2 | 实例元数据服务版本 2 | AWS 的加强版元数据服务，防御简单 SSRF |

---

## 甲方视角思考

1. **网络隔离优先** — 把 URL 拉取类业务放到独立子网，出口防火墙明确拒绝 RFC1918 和云服务元数据 IP，代码绕过再多也碰不到目标。
2. **云上必须关闭 IMDSv1** — AWS 实例统一要求 IMDSv2，并收窄实例角色权限，让 SSRF 即使命中元数据也拿不到高权限凭证。
3. **URL 解析=攻击面** — 任何业务接受外部 URL 都要过安全评审：是否解析后二次校验？是否禁用重定向？是否限制 scheme？
4. **监控带外请求** — 在态势感知/SIEM 中关注服务器对内网敏感端口、云元数据 IP 的异常出站连接，这是 SSRF 正在利用的强信号。

---

## Tomorrow — Day 23 Preview

**OS Command Injection** — we will continue the technical phase by looking at how attackers turn user input into shell commands, why filtering blacklisted characters almost always fails, and how to use parameterized APIs and strict allowlists to keep execution safe. The difficulty stays at ★★★☆☆ with more code-heavy examples.
