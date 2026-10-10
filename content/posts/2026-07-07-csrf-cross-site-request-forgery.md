---
title: "Day 14 — Csrf Cross Site Request Forgery"
date: 2026-07-07
tags:
  - daily
  - security
  - english
description: "- Difficulty: ★★★☆☆ Technical / 技术级"
---

- **Date**: 2026-07-21
- **Difficulty**: ★★★☆☆ (Technical / 技术级)
- **Source**: PortSwigger Web Security Academy + OWASP Foundation
- **Link**: https://portswigger.net/web-security/csrf | https://owasp.org/www-community/attacks/csrf

> **Cross-site request forgery** (跨站请求伪造, CSRF, pronounced "sea-surf") is a web security vulnerability that allows an attacker to **induce users to perform actions that they do not intend to perform**. Unlike XSS, where the attacker injects code *into* the victim's browser, CSRF tricks the victim's browser into making a request *on behalf of* the attacker — using the victim's own **authentication** (认证) and **session** (会话).

---

## 1. The Core Concept: Confused Deputy

CSRF is a **confused deputy** (混淆代理人) attack. The browser is the "deputy" — it holds the user's credentials and automatically attaches them to requests. The attacker "confuses" the browser into sending a request to a trusted site, and the browser obediently includes the victim's **session cookie** (会话 Cookie).

Here is the critical insight: **the attacker never sees the response**. CSRF is a **one-way** attack — the attacker can make the victim *do* something, but cannot *read* the result. This distinguishes it from XSS, where the attacker can exfiltrate data.

> 中文简释：CSRF 的本质是"借刀杀人"——攻击者不需要偷你的密码，只需要骗你的浏览器替他发一个请求，浏览器会自动带上你的登录凭证。

---

## 2. How a CSRF Attack Works

Consider a banking application where users can transfer money via this HTTP request:

```http
POST /transfer HTTP/1.1
Host: bank.com
Cookie: session=abc123

amount=1000&toAccount=12345
```

An attacker hosts a malicious web page with this HTML:

```html
<form action="https://bank.com/transfer" method="POST">
    <input type="hidden" name="amount" value="10000">
    <input type="hidden" name="toAccount" value="attacker_account">
</form>
<script>
    document.forms[0].submit();
</script>
```

When a **logged-in** victim visits the attacker's page, the form auto-submits. The browser sends the request to `bank.com` and **automatically attaches** the victim's session cookie. The bank processes the transfer as if the victim initiated it.

**Three conditions** must be met for a successful CSRF:
1. The action performs a **state-changing operation** (状态变更操作) — e.g., transfer money, change email, delete account
2. The application relies **solely on session cookies** for authentication — no secondary verification
3. The attacker can **predict all required parameters** — no unpredictable tokens or values

> 中文简释：攻击者构造一个自动提交的表单，受害者只要访问恶意页面、且正好登录了目标网站，浏览器就会"忠实地"替攻击者发出转账请求。

---

## 3. CSRF vs XSS — Key Differences

| Dimension | CSRF | XSS |
|-----------|------|-----|
| Who executes the attack? | Victim's browser (unwittingly) | Attacker's script (in victim's browser) |
| Does attacker see the response? | **No** — one-way | **Yes** — full read access |
| Requires user to be logged in? | Yes | Not necessarily |
| Primary defense | Anti-CSRF token | Output encoding + CSP |
| Trust model abused | Browser auto-sends cookies | Same-origin policy bypass |

A simple mnemonic: **XSS = "I can run code as you"; CSRF = "I can make you do things."**

> 中文简释：XSS 是"我冒充你执行代码"，CSRF 是"我让你替我做事"。XSS 能读响应，CSRF 只能发请求。

---

## 4. GET-Based CSRF: The Dangerous Convenience

Some applications perform **state-changing actions** via GET requests — a violation of HTTP semantics. GET should only **retrieve** data, never **modify** it.

**Vulnerable example:**

```http
GET /changeEmail?email=attacker@evil.com HTTP/1.1
Host: vulnerable-app.com
Cookie: session=xyz789
```

An attacker can trigger this with a simple image tag — **no JavaScript required**:

```html
<img src="https://vulnerable-app.com/changeEmail?email=attacker@evil.com" style="display:none">
```

The browser tries to load the "image," which sends the GET request with cookies attached. This works even if JavaScript is disabled, and even in **HTML emails** (if images are loaded).

> 中文简释：用 GET 请求做写操作是最危险的 CSRF 场景——一张 `<img>` 标签就能触发，连 JavaScript 都不需要。

---

## 5. POST-Based CSRF: Still Exploitable

Many developers believe POST requests are immune to CSRF. They are not. An attacker can construct an auto-submitting form (as shown in Section 2) that sends a POST request cross-origin.

However, there is one important constraint: with a standard HTML form POST, the attacker **cannot set custom HTTP headers** (如 `Content-Type: application/json`). The browser only allows:
- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `text/plain`

If an API endpoint only accepts `Content-Type: application/json`, a simple form-based CSRF will fail. But this is **not** a reliable defense — the server's **CORS** (Cross-Origin Resource Sharing / 跨源资源共享) policy determines whether the browser blocks the *response*, not whether the *request* is sent. A "preflight-free" request still reaches the server.

> 中文简释：POST 不能防 CSRF。即使 API 只接受 JSON，也不能完全依赖 Content-Type 做防护——跨域请求仍可能到达服务器。

---

## 6. Defense Layer 1: Anti-CSRF Tokens (Synchronizer Token Pattern)

The most robust defense. The server generates a **cryptographically random token** (密码学随机令牌) and embeds it in:
1. A hidden form field in the HTML response
2. (Optionally) A custom HTTP header for AJAX requests

When the form is submitted, the server compares the token in the form data with the token stored in the **server-side session** (服务端会话). If they don't match, the request is rejected.

**Example — server generates token:**

```java
// On page render
String csrfToken = generateRandomToken(); // e.g., 256-bit random
session.setAttribute("csrfToken", csrfToken);

// Embed in HTML
out.write("<input type='hidden' name='csrfToken' value='" + csrfToken + "'>");
```

**Example — server validates token:**

```java
// On form submission
String submittedToken = request.getParameter("csrfToken");
String sessionToken = (String) session.getAttribute("csrfToken");

if (submittedToken == null || !submittedToken.equals(sessionToken)) {
    response.sendError(403, "CSRF token validation failed");
    return;
}
// Process the request...
```

**Key rules for tokens:**
- Token must be **unpredictable** — use a CSPRNG (Cryptographically Secure Pseudo-Random Number Generator)
- Token must be tied to the **user's session** — a global token shared across users is useless
- Token must be validated on **every state-changing request**
- Token should be transmitted in a **custom header** (e.g., `X-CSRF-Token`) for AJAX calls — this forces a preflight CORS check, adding another barrier

> 中文简释：Anti-CSRF Token 是最核心的防御——服务器发一个随机令牌嵌入表单，提交时校验。令牌必须不可预测、绑定会话、每次写操作都验证。

---

## 7. Defense Layer 2: SameSite Cookie Attribute

The **SameSite** attribute tells the browser whether to include cookies in **cross-site requests** (跨站请求):

| Value | Behavior | CSRF Protection |
|-------|----------|-----------------|
| `SameSite=Strict` | Cookie only sent on **same-site** requests | ✅ Strongest — blocks all CSRF |
| `SameSite=Lax` | Cookie sent on top-level navigations (GET) only | ⚠️ Partial — blocks POST CSRF, but GET-based CSRF may still work |
| `SameSite=None` | Cookie sent on all requests | ❌ No CSRF protection (requires `Secure`) |

```http
Set-Cookie: session=abc123; SameSite=Strict; Secure; HttpOnly
```

**`SameSite=Lax`** is the browser default in modern Chrome, Firefox, and Edge. This means most cookies are already partially protected. However, `Lax` still allows GET-based CSRF on top-level navigations, and some flows (like OAuth callbacks) may break with `Strict`.

> 中文简释：`SameSite=Strict` 能从浏览器层面阻断 CSRF，但可能影响合法的跨站跳转流程。`Lax` 是现代浏览器默认值，提供了基础保护但不够完整。

---

## 8. Defense Layer 3: Double Submit Cookie Pattern

An alternative to server-side token storage. The server sends the CSRF token in **two** places:
1. As a **cookie** (accessible by JavaScript)
2. JavaScript reads the cookie and includes the value in a **custom header** (e.g., `X-CSRF-Token`)

The server verifies that the cookie value and the header value **match**.

**Why this works**: An attacker on `evil.com` cannot read cookies from `bank.com` (same-origin policy), so they cannot set the custom header to the correct value. The attacker can *send* the cookie (it auto-attaches), but cannot *read* it to put it in the header.

```javascript
// Client-side: read cookie, send in header
function getCookie(name) {
    let cookie = document.cookie.match('(^|;)\\s*' + name + '\\s*=\\s*([^;]+)');
    return cookie ? cookie.pop() : '';
}

fetch('/api/transfer', {
    method: 'POST',
    headers: {
        'X-CSRF-Token': getCookie('csrfToken'),
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({ amount: 1000, to: '12345' })
});
```

> 中文简释：Double Submit 模式无需服务端存储——令牌同时放在 Cookie 和自定义请求头中，服务器只验证两者是否一致。攻击者能发 Cookie 但读不到 Cookie 值，无法伪造请求头。

---

## 9. Common CSRF Bypass Techniques

Attackers (and penetration testers) often find that "protected" applications still have CSRF weaknesses:

| Bypass Technique | How It Works |
|-----------------|--------------|
| **Token not validated** | Server receives token but never checks it — just checks if the parameter *exists* |
| **Token not tied to session** | Token is valid across different user sessions |
| **Token in URL** | Token passed in query string; attacker can use `Referer` leakage to harvest |
| **GET request for state change** | SameSite=Lax allows GET CSRF; token only checked on POST |
| **Subdomain takeover** | Attacker controls a subdomain (e.g., `blog.example.com`); cookies with `Domain=.example.com` are sent |
| **JSON content-type trick** | Some frameworks accept `text/plain` and still parse as JSON; form can submit `text/plain` cross-origin |
| **Method override** | Application supports `_method=POST` via GET parameter to bypass SameSite=Lax |

> 中文简释：CSRF 防御常有实现缺陷——令牌不校验、不绑定会话、GET 请求漏验、子域接管绕过 SameSite 等。安全测试时要逐项验证。

---

## 10. CSRF in Modern Applications: New Challenges

### REST APIs and SPA (Single-Page Applications)

Modern SPAs (React, Vue, Angular) communicate via **fetch/XHR** with JSON payloads. These requests typically include:
- `Authorization: Bearer <JWT>` header — **not** automatically sent like cookies
- `Content-Type: application/json` — requires a CORS preflight

If authentication uses **bearer tokens** (like JWT stored in localStorage) instead of cookies, CSRF is largely irrelevant — the browser does not auto-attach bearer tokens. However, if the JWT is stored in an **HttpOnly cookie**, CSRF risk returns.

### GraphQL

GraphQL endpoints that accept `application/json` via POST may seem safe, but some implementations also accept `application/x-www-form-urlencoded` or even GET — re-introducing CSRF risk.

> 中文简释：现代 SPA + Bearer Token 认证天然免 CSRF，但如果 Token 放在 Cookie 中，风险又回来了。架构变了，但 CSRF 的根因没变——浏览器自动携带凭证。

---

## Key Terms

| English | 中文 | Note |
|--------|------|------|
| Cross-Site Request Forgery (CSRF) | 跨站请求伪造 | 诱导用户浏览器替攻击者发送请求 |
| Confused Deputy | 混淆代理人 | CSRF 的攻击模型，浏览器被"混淆"为代理人 |
| State-Changing Operation | 状态变更操作 | 修改数据的服务器端操作，如转账、改密码 |
| Session Cookie | 会话 Cookie | 浏览器自动携带的认证凭证 |
| Anti-CSRF Token | 防 CSRF 令牌 | 服务器生成的随机值，验证请求来源 |
| Synchronizer Token Pattern | 同步令牌模式 | 令牌存于服务端会话，提交时比对 |
| Double Submit Cookie | 双重提交 Cookie | 令牌同时放 Cookie 和请求头，验证一致性 |
| SameSite Attribute | SameSite 属性 | Cookie 属性，限制跨站请求时是否携带 |
| SameSite=Strict | 严格模式 | 仅同站请求携带 Cookie，最强 CSRF 防护 |
| SameSite=Lax | 宽松模式（默认） | 仅顶层 GET 导航携带 Cookie |
| Cross-Origin Resource Sharing (CORS) | 跨源资源共享 | 浏览器机制，控制跨域请求的响应访问 |
| Preflight Request | 预检请求 | CORS 中 OPTIONS 请求，检查跨域权限 |
| Bearer Token | 持有者令牌 | Authorization 头中的令牌，非自动携带 |
| Subdomain Takeover | 子域名接管 | 攻击者控制子域名，利用 Domain Cookie 绕过 |
| Method Override | 方法覆盖 | 通过参数改写 HTTP 方法，绕过 SameSite 限制 |

---

## 甲方视角思考

- CSRF 防御优先级：Anti-CSRF Token 是根本，SameSite=Lax 是基线补充，两者缺一不可。
- API 网关层统一注入 Token 校验中间件，别让每个业务团队自己实现——实现缺陷是 CSRF 绕过的主要原因。
- 审计重点：所有写操作（POST/PUT/DELETE）是否都验证 Token？GET 请求是否存在状态变更？子域是否有可被接管的风险？
- 架构升级方向：前后端分离 + Bearer Token（非 Cookie）天然免疫 CSRF，新系统优先采用此模式。

---

## 明日预告

**Day 15: Insecure Direct Object Reference (IDOR) — When Access Control Is Just a Guess**  
我们从请求伪造转向访问控制失效，学习 IDOR 漏洞——攻击者只需改一个 ID 就能访问别人的数据，这是 OWASP A01 Broken Access Control 的经典案例。
