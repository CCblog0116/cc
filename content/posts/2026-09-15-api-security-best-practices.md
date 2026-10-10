---
title: "Day 30 — API Security Best Practices: Building a Defensible API Surface"
date: 2026-09-15
tags:
  - daily
  - security
  - english
description: "⭐ Difficulty: ★★★☆☆ Technical"
---

📅 **Date:** September 15, 2026  
⭐ **Difficulty:** ★★★☆☆ Technical  
📰 **Source:** OWASP API Security Top 10:2023 + PortSwigger API Security + NIST SP 800-207  
🔗 **Reference:** [https://owasp.org/API-Security/editions/2023/en/0x00-header/](https://owasp.org/API-Security/editions/2023/en/0x00-header/)

---

## 1. Why API Security Deserves Its Own Playbook

Modern applications are glued together by **Application Programming Interfaces (APIs)**（应用程序接口）. Every mobile app, single-page application, microservice, and third-party integration relies on APIs to exchange data. When APIs are exposed to the internet, they become a high-value target: they sit at the boundary between untrusted clients and sensitive backend systems.

Unlike traditional web pages, APIs often expose rich functionality directly. A single endpoint may allow creating, reading, updating, and deleting records. If authentication or authorization is weak, an attacker can automate abuse at scale. 对甲方而言，API 资产清单往往不完整，影子 API 和未下线的旧版本是常见的突破口。

---

## 2. OWASP API Security Top 10: A Quick Map

The **OWASP API Security Top 10:2023**（OWASP API 安全 Top 10） lists the most critical risks facing APIs today. Here is the short version:

| Rank | Risk | Core Idea |
|------|------|-----------|
| API1:2023 | Broken Object Level Authorization | Users can access other users' objects by guessing IDs. |
| API2:2023 | Broken Authentication | Weak tokens, credential stuffing, weak MFA. |
| API3:2023 | Broken Object Property Level Authorization | Over-fetching or over-posting sensitive fields. |
| API4:2023 | Unrestricted Resource Consumption | No rate limits lead to abuse and denial of wallet. |
| API5:2023 | Broken Function Level Authorization | Low-privilege users can call admin functions. |
| API6:2023 | Unrestricted Access to Sensitive Business Flows | Automation of business flows like bulk ticket buying. |
| API7:2023 | Server-Side Request Forgery | APIs fetch URLs supplied by users. |
| API8:2023 | Security Misconfiguration | Default configs, verbose errors, missing patches. |
| API9:2023 | Improper Inventory Management | Shadow APIs, old versions, dev endpoints exposed. |
| API10:2023 | Unsafe Consumption of APIs | Trusting third-party APIs without validation. |

This list is not just for developers. For security teams, it is a checklist for **API security assessments**（API 安全评估） and **runtime monitoring**（运行时监控）.

---

## 3. Authentication and Authorization

Authentication asks, "Who are you?" Authorization asks, "What are you allowed to do?" APIs fail when either question is answered incorrectly.

Use **OAuth 2.0**（开放授权协议） with **OpenID Connect (OIDC)**（OpenID 连接协议） for delegated access and identity. Avoid building custom token schemes. When using **JWT**（JSON Web Token）, follow the hard lessons from Day 29: whitelist the algorithm, use strong secrets, reject `none`, and validate token binding where possible.

Authorization must be enforced at every function and object level. Do not assume that because a user is authenticated, they are authorized. This is the root cause of **Broken Object Level Authorization (BOLA)**（对象级授权失效）, formerly known as **Insecure Direct Object Reference (IDOR)**（不安全的直接对象引用）.

> 简短中文提醒：在 SSO 接口和金域医学内部 API 中，除了验证令牌签名，还要校验用户角色、资源所属关系，避免低权限用户横向越权访问其他用户数据。

---

## 4. Rate Limiting and Throttling

Without **rate limiting**（速率限制）, an attacker can brute-force credentials, scrape data, or flood expensive operations. Rate limiting should be applied per user, per IP, and per API key, not just globally.

A simple **leaky bucket**（漏桶） or **token bucket**（令牌桶） algorithm can smooth traffic. More advanced setups use sliding windows and per-endpoint budgets. Critical operations such as login, password reset, and payment initiation deserve tighter limits.

Example principle in pseudo-policy:

```
GET /api/v1/records    → 100 requests per minute per user
POST /api/v1/login     → 5 attempts per minute per IP
POST /api/v1/transfer  → 1 request per 5 seconds per user
```

---

## 5. Input Validation and Schema Enforcement

Never trust client input. Use a strict **JSON Schema**（JSON 模式） or similar contract to validate every field: type, length, format, and allowed values. Reject requests that contain unexpected fields rather than silently ignoring them.

For file uploads, enforce **allowlists**（白名单） of MIME types and extensions, scan files with antivirus or sandboxing, and store uploaded files outside the web root. 这与 Day 24（文件上传漏洞）主题相呼应。

Use **parameterized queries**（参数化查询） everywhere. APIs are a common entry point for SQL injection and NoSQL injection because attackers can send structured payloads directly.

---

## 6. Error Handling and Least Information Disclosure

API error responses should help legitimate developers, not attackers. Avoid returning **stack traces**（堆栈跟踪）, internal file paths, database schemas, or detailed version numbers. Use generic error codes internally and map them to sanitized external messages.

Bad response:

```json
{
  "error": "MySQL syntax error near 'OR 1=1' at line 1"
}
```

Good response:

```json
{
  "error": "invalid_request",
  "message": "The request could not be processed."
}
```

Centralize error handling in an **API gateway**（API 网关） or middleware layer to ensure consistency.

---

## 7. Logging, Monitoring, and Anomaly Detection

Log enough to investigate incidents, but never log secrets, tokens, or full credit card numbers. Useful API log fields include:

- Request method, path, and query parameters
- Response status code and latency
- Authenticated user or client ID
- Source IP and user agent
- API version and route handler

Feed these logs into a **SIEM**（安全信息与事件管理） or **SOC**（安全运营中心） platform. Build detection rules for unusual patterns: sudden spikes in 4xx/5xx errors, large data exports, access from new geolocations, or repeated authorization failures. 对甲方来说，态势感知平台（SIP）和流量探针已经部署，应重点配置 API 异常行为的告警规则。

---

## 8. API Gateway and Defense in Depth

An **API gateway**（API 网关） is a reverse proxy that centralizes cross-cutting concerns: authentication, rate limiting, SSL termination, request routing, versioning, and logging. By pushing these controls into the gateway, you reduce the chance that individual backend teams forget them.

However, defense in depth means the gateway is not the only guardrail. Backend services must still validate input, enforce authorization, and handle errors safely. A WAF or gateway rule can be bypassed, so never rely on it alone.

---

## 9. API Versioning and Deprecation

**API versioning**（API 版本控制） lets you ship improvements without breaking existing clients. Common strategies include URL paths (`/v1/`, `/v2/`), query parameters, or custom headers. Whatever strategy you choose, document it and enforce a deprecation schedule.

Old versions are a classic source of **improper inventory management**（资产管理不当）. A `/v1/` endpoint may lack security controls added in `/v2/`, yet remain accessible because no one remembered to retire it. Track every API in a central inventory and sunset versions with a formal process.

---

## 10. Defense Checklist

| Control | Action |
|---------|--------|
| Authentication | Use OAuth 2.0 / OIDC; never accept `alg:none` JWT |
| Authorization | Enforce object-level and function-level checks on every request |
| Rate limiting | Apply per-user, per-IP, and per-endpoint limits |
| Input validation | Use strict schemas; reject unknown fields |
| Injection prevention | Parameterized queries; output encoding |
| Error handling | Sanitize error messages; log details server-side only |
| Logging | Send API logs to SIEM; alert on anomalies |
| Gateway | Centralize auth, rate limiting, TLS, and routing |
| Inventory | Maintain an API catalog; retire old versions |
| Third-party trust | Validate data from upstream APIs before acting on it |

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| API (Application Programming Interface) | 应用程序接口 | Allows software components to communicate |
| OWASP API Security Top 10 | OWASP API 安全 Top 10 | Dedicated risk list for APIs, last updated 2023 |
| BOLA (Broken Object Level Authorization) | 对象级授权失效 | User accesses others' objects by tampering IDs |
| Authentication | 身份认证 | Verifies who the caller is |
| Authorization | 授权 | Determines what the caller may do |
| OAuth 2.0 | 开放授权协议 | Delegated authorization framework |
| OIDC (OpenID Connect) | OpenID 连接协议 | Identity layer on top of OAuth 2.0 |
| JWT (JSON Web Token) | JSON 网络令牌 | Compact token used for stateless auth |
| Rate limiting | 速率限制 | Controls how many requests a client can send |
| Throttling | 流量控制 | Slows or blocks excessive traffic |
| JSON Schema | JSON 模式 | Declarative validation rules for JSON input |
| API gateway | API 网关 | Central entry point for API traffic and policies |
| SIEM | 安全信息与事件管理 | Platform for aggregating and analyzing security logs |
| SOC | 安全运营中心 | Team and tooling for continuous security monitoring |
| Stack trace | 堆栈跟踪 | Internal debugging output that should not leak |
| Parameterized query | 参数化查询 | SQL-safe query pattern using placeholders |
| Allowlist | 白名单 | Explicit list of allowed values |
| Deprecation | 弃用 | Process of retiring an old API version |
| Defense in depth | 纵深防御 | Multiple independent security layers |

---

## 甲方视角思考

- **API 资产盘点**：梳理内外部 API 清单，包括版本、负责人、认证方式和暴露面，重点排查未下线的旧版本和影子 API。  
- **接口权限审计**：对核心 API（如患者信息查询、病理报告发送接口）执行 BOLA/IDOR 测试，确保每次请求都校验资源归属。  
- **网关统一管控**：推动 API 网关集中配置认证、速率限制和日志转发，避免各业务线重复造轮子导致策略遗漏。  
- **API 流量监控**：在 SIP / 流量探针上配置异常检测规则，关注高频 401/403、异常数据导出和第三方 API 回连行为。  

---

## Tomorrow's Preview — Day 31

**Topic:** Cloud Security Fundamentals  
**What to expect:** We'll move from application-layer APIs to cloud infrastructure — covering the **shared responsibility model**（责任共担模型）, **Identity and Access Management (IAM)**（身份与访问管理）, **cloud metadata service**（云元数据服务） risks like IMDSv1, and **object storage security**（对象存储安全） such as S3 bucket misconfigurations. As a defender, how do you audit cloud assets and enforce a secure baseline? Day 31 lays the groundwork.
