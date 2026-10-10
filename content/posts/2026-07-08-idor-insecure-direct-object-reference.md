---
title: "Day 15 — Idor Insecure Direct Object Reference"
date: 2026-07-08
tags:
  - daily
  - security
  - english
description: "- Difficulty: ★★★☆☆ Technical / 技术级"
---

- **Date**: 2026-07-22
- **Difficulty**: ★★★☆☆ (Technical / 技术级)
- **Source**: PortSwigger Web Security Academy + OWASP Foundation
- **Link**: https://portswigger.net/web-security/access-control/idor | https://owasp.org/Top10/A01_2021-Broken_Access_Control/

> **Insecure Direct Object Reference** (不安全的直接对象引用, **IDOR**) is an **access control** (访问控制) vulnerability that occurs when an application exposes a reference to an internal implementation object — such as a database key, file path, or user ID — and fails to verify whether the user is authorized to access that object. IDOR appears as **A01:2021 – Broken Access Control** (失效的访问控制) in the OWASP Top 10, the most common and impactful web application risk today.

---

## 1. The Core Idea: Trusting What the User Sends

Modern web applications use **identifiers** (标识符) to locate resources. These identifiers often appear in URLs, query strings, request bodies, or HTTP headers:

```
https://shop.example.com/order?orderId=12345
https://bank.example.com/api/accounts/998877
https://cloud.example.com/documents?file=report_2026.pdf
```

When the application retrieves the resource based *only* on that identifier, without checking whether the logged-in user owns it, the result is IDOR. The attacker simply changes the identifier and gains unauthorized access.

The critical mistake is **authorization by obscurity** (靠模糊性做授权): developers assume that because an ID is random-looking, no one will guess it. IDOR proves that obscurity is not a substitute for proper access control.

> 中文简释：IDOR 的本质是"服务器盲目信任用户传来的 ID"——只要改一个数字或文件名，就能访问别人的数据。授权不能靠 ID 难猜，必须显式校验所有权。

---

## 2. A Classic Example: Changing One Number

Imagine an e-commerce site where users view their order history:

```http
GET /orders/12345 HTTP/1.1
Host: shop.example.com
Cookie: session=abc123
```

The server responds with the order details for user Alice. An attacker Bob, logged into his own account, changes the request:

```http
GET /orders/12346 HTTP/1.1
Host: shop.example.com
Cookie: session=xyz789
```

If the server returns someone else's order — including shipping address, payment method, and purchased items — the application has an IDOR vulnerability. The server validated *authentication* (Bob is logged in) but failed to validate *authorization* (Bob should not see Alice's order).

> 中文简释：经典场景就是改 URL 里的 ID。服务器只验证"你是谁"，没验证"你能不能看这个"——认证和授权是两回事。

---

## 3. Why IDOR Is Everywhere

IDOR is one of the most frequently reported vulnerabilities in **bug bounty programs** (漏洞赏金计划) for three reasons:

| Reason | Explanation |
|--------|-------------|
| **Simple to exploit** | Often just increment a number or swap a filename; no special tools needed |
| **Easy to miss in design** | Developers build APIs for "their own frontend" and forget attackers can call them directly |
| **High business impact** | A single IDOR can leak PII, financial records, medical data, or intellectual property |

Because IDOR is an **access control** flaw rather than an input validation flaw, traditional **WAFs** (Web Application Firewalls / Web 应用防火墙) and signature-based scanners often miss it. The request looks completely legitimate — it just accesses the wrong object.

> 中文简释：IDOR 在众测里高频出现，因为它 exploit 简单、设计阶段容易忽略、且影响巨大。WAF 通常拦不住，因为请求本身看起来完全正常。

---

## 4. Where IDOR Hides: Common Locations

IDOR can appear anywhere the application uses a user-supplied reference to fetch a resource.

### 4.1 URL Path Parameters

```http
GET /api/invoices/8821 HTTP/1.1
```

Change `8821` to `8822` and you may see another user's invoice.

### 4.2 Query String Parameters

```http
GET /download?file=alice_salary.pdf HTTP/1.1
```

Change the filename to `bob_salary.pdf`.

### 4.3 Request Body in POST/PUT APIs

```json
{
  "userId": 42,
  "newEmail": "attacker@evil.com"
}
```

If the server does not verify that `userId` belongs to the caller, you can change any user's email.

### 4.4 Hidden Form Fields

```html
<input type="hidden" name="account_id" value="5678">
```

Intercept the form submission and modify the hidden value.

### 4.5 API Versioning and Bulk Endpoints

Old API versions often lack authorization checks that newer versions have:

```http
GET /v1/users/export?department=all HTTP/1.1
```

Bulk export endpoints are prime IDOR targets because they return large volumes of data.

> 中文简释：IDOR 不只在 URL 参数里。请求体、隐藏表单字段、文件路径、旧版 API、批量导出接口都可能中招。

---

## 5. Testing for IDOR: A Methodical Approach

When hunting for IDOR, follow this workflow:

1. **Create two accounts**: attacker account + victim account
2. **Browse the application** as the victim and capture legitimate object identifiers
3. **Switch to the attacker account** and replay the same requests with the victim's identifiers
4. **Watch for successful access** to the victim's data
5. **Test variations**: try deleting `/123`, replacing numeric IDs with UUIDs, changing HTTP methods, or switching API versions

A useful technique is **horizontal IDOR testing** vs **vertical IDOR testing**:

| Type | What It Tests | Example |
|------|---------------|---------|
| **Horizontal IDOR** (水平越权) | Access data of a peer user with the same role | User A reads User B's order |
| **Vertical IDOR** (垂直越权) | Access functionality or data reserved for a higher-privilege role | Regular user accesses admin reports |

> 中文简释：测 IDOR 的标准方法是开两个账号互相换 ID。水平越权是同角色用户互访，垂直越权是低角色访问高权限功能。

---

## 6. Prevention: Design Authorization Into Every Endpoint

There is no single magic header that fixes IDOR. The fix is **consistent access control enforcement** across every endpoint that handles a resource identifier.

### 6.1 Validate Ownership on Every Request

The server must check that the current user is allowed to access the requested object *before* returning it.

```python
# ❌ Vulnerable: trusts the user-supplied orderId
order = Order.objects.get(id=request.GET['orderId'])

# ✅ Safe: enforce that the order belongs to the current user
order = Order.objects.get(
    id=request.GET['orderId'],
    customer=request.user
)
```

### 6.2 Prefer Indirect Object References

Instead of exposing raw database IDs, map them to user-scoped references:

| Approach | Example |
|----------|---------|
| Raw database ID | `/orders/12345` |
| User-scoped index | `/orders/3` (the 3rd order of the current user) |
| Randomized token | `/orders/a1b2c3d4e5` |

OWASP calls this the **Indirect Reference Map** (间接引用映射). The application stores a mapping between internal IDs and short-lived, user-specific tokens.

### 6.3 Use UUIDs Instead of Sequential IDs

Sequential integers (`1, 2, 3...`) are trivial to enumerate. **Universally Unique Identifiers** (通用唯一识别码, UUIDs) make guessing much harder, though they are *not* a complete defense by themselves.

### 6.4 Avoid Mass Assignment

Frameworks that automatically bind request parameters to model fields can let attackers overwrite protected fields:

```json
{
  "userId": 42,
  "role": "admin",
  "newEmail": "attacker@evil.com"
}
```

Use **allowlists** (白名单) for writable fields and never let users set privilege-related attributes.

### 6.5 Centralize Authorization Logic

Do not scatter authorization checks across controllers. Use a single **authorization layer** (授权层) or middleware that every request must pass through. This reduces the chance that a new endpoint forgets to enforce access control.

> 中文简释：防 IDOR 的核心是"每个涉及资源 ID 的接口都要显式校验所有权"。UUID、间接引用映射、白名单字段、集中授权层都是有效补充，但不能替代所有权校验。

---

## 7. IDOR vs. Path Traversal vs. Information Disclosure

These vulnerabilities often overlap but are not the same:

| Vulnerability | Mechanism | Typical Identifier |
|---------------|-----------|-------------------|
| **IDOR** | Access control missing for a resource identifier | Numeric ID, UUID, filename |
| **Path Traversal** (路径遍历) | User escapes a restricted directory using `../` | File path |
| **Information Disclosure** (信息泄露) | Sensitive data leaked in error messages or responses | Stack traces, debug info |

A request like `GET /download?file=../../etc/passwd` is path traversal. A request like `GET /download?file=alice_report.pdf` changed to `bob_report.pdf` is IDOR.

> 中文简释：IDOR 是改 ID 越权访问资源；路径遍历是用 `../` 跳出目录；信息泄露是敏感数据意外暴露。三者可能同时出现，但机理不同。

---

## Key Terms

| English | 中文 | Note |
|--------|------|------|
| Insecure Direct Object Reference (IDOR) | 不安全的直接对象引用 | 通过篡改资源标识符越权访问数据 |
| Broken Access Control | 失效的访问控制 | OWASP 2021 A01，最普遍的 Web 安全风险 |
| Access Control | 访问控制 | 决定谁能访问什么资源的机制 |
| Authentication | 认证 | 验证"你是谁" |
| Authorization | 授权 | 验证"你能做什么" |
| Identifier | 标识符 | 指向资源的 ID、文件名、UUID 等 |
| Horizontal IDOR | 水平越权 | 同角色用户间越权访问 |
| Vertical IDOR | 垂直越权 | 低权限用户访问高权限功能/数据 |
| Indirect Reference Map | 间接引用映射 | 将内部 ID 映射为用户级随机令牌 |
| UUID (Universally Unique Identifier) | 通用唯一识别码 | 随机、难枚举的全局标识符 |
| Mass Assignment | 批量赋值 | 框架自动绑定请求字段到模型属性 |
| Allowlist | 白名单 | 仅允许明确列出的字段/操作 |
| Web Application Firewall (WAF) | Web 应用防火墙 | 对 IDOR 通常无效，因请求看似合法 |
| Path Traversal | 路径遍历 | 利用 `../` 访问目录外文件 |
| Information Disclosure | 信息泄露 | 敏感信息通过错误信息等渠道泄露 |
| PII (Personally Identifiable Information) | 个人可识别信息 | 姓名、地址、身份证号等敏感数据 |
| Bug Bounty Program | 漏洞赏金计划 | 企业向白帽黑客支付漏洞奖励的项目 |

---

## 甲方视角思考

- 认证 ≠ 授权：每个返回数据的接口都要问一句"当前用户是否有权访问这个对象"，而不是只问"他登录了吗"。
- 水平越权是甲方排查重点：用户中心、订单系统、发票下载、医疗/金融记录查询是 IDOR 高发区。
- 不要依赖 ID 难猜做安全：UUID 能提升枚举成本，但不能替代服务端所有权校验。
- SDL 接入点：在接口设计评审阶段强制要求"资源访问必须绑定用户/角色上下文"，比上线后扫描有效十倍。

---

## 明日预告

**Day 16: Path Traversal — Breaking Out of the Web Root**  
明天我们继续沿着访问控制这条线，学习路径遍历漏洞：攻击者如何用 `../` 逃离 Web 目录，读取服务器上的敏感文件。
