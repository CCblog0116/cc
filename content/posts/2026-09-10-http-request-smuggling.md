---
title: "Day 27 — HTTP Request Smuggling: The Vulnerability Hiding Between Your Proxies"
date: 2026-09-10
tags:
  - daily
  - security
  - english
description: "In 2019, security researcher James Kettle disclosed a critical class of vulnerabilities affecting reverse proxies （反向代理）, load balancers （负载均衡器）, and "
---

**Date:** 2026-09-10 | **Difficulty:** ★★★☆☆ Technical | **Source:** PortSwigger Web Security Academy / OWASP | **Link:** [PortSwigger — HTTP Request Smuggling](https://portswigger.net/web-security/request-smuggling), [OWASP — HTTP Request Smuggling](https://owasp.org/www-community/attacks/HTTP_Request_Smuggling)

---

## Why This Matters

In 2019, security researcher James Kettle disclosed a critical class of vulnerabilities affecting **reverse proxies** （反向代理）, **load balancers** （负载均衡器）, and **CDNs** （内容分发网络） deployed by Microsoft, Akamai, Cloudflare, Amazon, and dozens of Fortune 500 companies. The attack — **HTTP Request Smuggling** （HTTP 请求走私） — had been quietly living in the HTTP/1.1 specification since 1999, and almost every major vendor was vulnerable. One exploit on the right system could **poison the shared cache** （污染共享缓存）, **hijack other users' sessions** （劫持其他用户的会话）, and **bypass the WAF** （绕过 Web 应用防火墙） entirely.

The bug is invisible at the application layer. You do not need an injection payload, a stolen cookie, or a misconfigured ACL. You simply confuse two servers about where one HTTP request ends and the next one begins.

> HTTP 请求走私的核心：让前端代理和后端服务器对"一个请求的边界"产生分歧。

---

## What Is HTTP Request Smuggling?

**HTTP Request Smuggling** is a technique that exploits disagreements between an **HTTP front-end** （HTTP 前端，如反向代理/CDN/WAF） and a **back-end server** （后端服务器） about how to parse the boundaries of incoming HTTP/1.1 requests.

HTTP/1.1 offers two different mechanisms for marking where a request body ends:

| Mechanism | Header | How It Works |
|-----------|--------|--------------|
| **Content-Length** | `Content-Length: N` | The body is exactly N bytes long. |
| **Transfer-Encoding** | `Transfer-Encoding: chunked` | The body is sent in **chunks** （分块）; each chunk declares its size, and a zero-sized chunk marks the end. |

When both headers are present — or when one of them is malformed — the front-end and the back-end may pick **different mechanisms** to delimit the request. The attacker slips an extra, hidden request inside what the front-end believes is one single request body. The back-end, parsing differently, treats the smuggled portion as the **start of the next request** from the same TCP connection.

The result: the attacker's request is executed by the back-end in the context of a **victim user who arrives next on the connection**.

---

## The Two Classic Variants

### 1. CL.TE — Front-end uses Content-Length, Back-end uses Transfer-Encoding

```
POST / HTTP/1.1
Host: example.com
Content-Length: 44
Transfer-Encoding: chunked

0

GET /admin/delete-user?id=123 HTTP/1.1
Host: example.com
```

- The **front-end** reads `Content-Length: 44` and forwards all 44 bytes (including the chunked headers and the smuggled request) to the back-end.
- The **back-end** sees `Transfer-Encoding: chunked`, reads the `0\r\n\r\n` as the end of the chunked body, and treats the bytes after it as **a brand-new request** belonging to whoever uses the same TCP connection next.

### 2. TE.CL — Front-end uses Transfer-Encoding, Back-end uses Content-Length

```
POST / HTTP/1.1
Host: example.com
Content-Length: 4
Transfer-Encoding: chunked

5c
GET /admin HTTP/1.1
Host: example.com
Content-Length: 15

x=1
0

```

- The **front-end** processes the chunked body and forwards only the chunked content up to the terminating `0`.
- The **back-end** reads `Content-Length: 4`, takes the next 4 bytes as the body, and treats everything after as the next request — in this case, the smuggled `GET /admin`.

---

## Why This Is Devastating

A successful smuggling attack enables several downstream exploits:

1. **Session Hijacking** — The smuggled request is processed in the context of the **next user on the TCP connection**. If that user's browser smuggles an `Authorization: Bearer <token>` header or a session cookie, the attacker captures it in the response to a request they control.
2. **Cache Poisoning** — A smuggled response can be stored against a benign URL, causing all subsequent visitors who request that URL to receive the attacker's malicious HTML.
3. **WAF / ACL Bypass** — The front-end WAF only inspects the request the front-end thinks it is forwarding. The smuggled portion is never examined.
4. **Internal Service Scanning** — The smuggled request reaches the back-end directly, allowing the attacker to pivot into **internal-only endpoints** （仅内网可见的端点） that the front-end would normally block.

---

## Defense: How To Stop Smuggling

The fix is architectural, not just a code patch.

| Defense | Description |
|---------|-------------|
| **Use HTTP/2 end-to-end** | HTTP/2 has a single, unambiguous framing layer (binary, length-prefixed frames). It is not vulnerable to this class of attack. |
| **Normalize requests at the front-end** | Strip duplicate or obfuscated headers (`Transfer-Encoding: chunked` with extra spaces or line terminators) before forwarding. |
| **Reject ambiguous requests** | If both `Content-Length` and `Transfer-Encoding` are present, drop the request. Do not guess. |
| **Disable connection reuse between front-end and back-end** | Each back-end connection handles one request only. Smuggling requires connection reuse. (Trade-off: major performance hit.) |
| **Patch parsers to comply with RFC 9112** | The 2022 RFC clarifies that `Transfer-Encoding` must take precedence over `Content-Length`; non-compliant parsers remain vulnerable. |

In a Python (Flask) reverse-proxy setup, the simplest hardening is at the front-end:

```python
# Reject any request that carries both headers — unambiguous smuggling signal.
if "Content-Length" in request.headers and "Transfer-Encoding" in request.headers:
    abort(400, "Ambiguous request framing")
```

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| HTTP Request Smuggling | HTTP 请求走私 | Exploiting front-end / back-end parsing disagreement |
| Content-Length | 内容长度 | HTTP/1.1 body length marker (decimal byte count) |
| Transfer-Encoding: chunked | 分块传输编码 | HTTP/1.1 streaming body mechanism |
| Reverse proxy | 反向代理 | Nginx, HAProxy, Envoy, etc. sitting in front of origin servers |
| Load balancer | 负载均衡器 | Distributes requests across back-end pool |
| CDN | 内容分发网络 | Cloudflare, Akamai, Fastly, etc. |
| Front-end / Back-end | 前端 / 后端 | The two servers whose parsers disagree |
| CL.TE | CL.TE 走私 | Front-end uses CL, back-end uses TE |
| TE.CL | TE.CL 走私 | Front-end uses TE, back-end uses CL |
| TCP connection reuse | TCP 连接复用 | Required precondition for smuggling |
| Cache poisoning | 缓存投毒 | Smuggled response cached against benign URL |
| WAF bypass | WAF 绕过 | Front-end WAF does not inspect smuggled portion |
| Session hijacking | 会话劫窃 | Stealing the next user's credentials on the same connection |
| Connection pipelining | 连接管线化 | Sending multiple HTTP requests over one TCP connection |
| RFC 9112 | RFC 9112 | Modern HTTP/1.1 message framing specification (2022) |
| Binary framing | 二进制分帧 | HTTP/2 framing; not vulnerable to smuggling |
| HTTP/1.1 | HTTP/1.1 | Text-based protocol susceptible to smuggling |

---

## 甲方视角思考

- 上线的应用如果前面挂了 Nginx / Envoy / SLB，请确认 WAF 是否会**剥离**而非**忽略**重复或异常的 `Transfer-Encoding` 头。
- 内部红队演练时，主动对 WAF/CDN 与源站之间的请求走私场景做专项检测（Burp Suite HTTP Smuggler 插件仍是主流工具）。
- 一旦涉及多级代理链（CDN → WAF → 反向代理 → 应用服务器），每一跳都可能被攻击者利用"解析分歧"做放大。
- 把 HTTP/2 作为内部服务间通信的硬性标准可显著降低该类风险面。

---

## 明日预告

**Day 28 — Insecure Deserialization: When Pickles Become Weapons.** We move from "smuggling HTTP packets" to "smuggling objects." We will look at Python `pickle`, Java `ObjectInputStream`, PHP `unserialize`, and the gadget chains that turn a single deserialization call into remote code execution.
