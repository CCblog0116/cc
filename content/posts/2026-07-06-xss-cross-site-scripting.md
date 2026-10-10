---
title: "Day 13 — Xss Cross Site Scripting"
date: 2026-07-06
tags:
  - daily
  - security
  - english
description: "- Difficulty: ★★★☆☆ Technical / 技术级"
---

- **Date**: 2026-07-20
- **Difficulty**: ★★★☆☆ (Technical / 技术级)
- **Source**: PortSwigger Web Security Academy + OWASP Foundation
- **Link**: https://portswigger.net/web-security/cross-site-scripting | https://owasp.org/www-community/Types_of_Cross_Site_Scripting

> **Cross-site scripting** (跨站脚本攻击, XSS) is a **web security vulnerability** (Web 安全漏洞) that allows an attacker to compromise the interactions that users have with a vulnerable application. While SQL injection targets the **database** (数据库), XSS targets the **browser** (浏览器) — injecting malicious JavaScript that executes in the victim's session. It is the second most prevalent issue in the OWASP Top 10, found in roughly two-thirds of all applications.

---

## 1. The Core Problem: Bypassing the Same-Origin Policy

Browsers enforce the **same-origin policy** (同源策略, SOP) to prevent one website from reading data belonging to another. XSS circumvents this policy entirely — when malicious JavaScript runs inside the victim's browser on the vulnerable site, it has full access to that site's data, cookies, and APIs, as if the attacker were the user.

An XSS attack typically follows this flow:

1. The attacker finds a way to inject malicious JavaScript into a web page
2. A victim visits the compromised page
3. The victim's browser executes the attacker's script **in the context of the vulnerable application**
4. The script can steal **session cookies** (会话 Cookie), perform actions on behalf of the user, redirect to phishing pages, or log keystrokes

> 中文简释：同源策略本应阻止网站之间互访数据，但 XSS 让恶意脚本在目标站点内执行，等于"合法"地绕过了这道防线。

---

## 2. Three Types of XSS

| Type | Where the Payload Comes From | Severity | Key Characteristic |
|------|------------------------------|----------|-------------------|
| **Reflected XSS** (反射型 XSS) | Current HTTP request | Medium–High | One-shot; victim must click a crafted link |
| **Stored XSS** (存储型 XSS) | Website's database | **Critical** | Persistent; every visitor is affected |
| **DOM-based XSS** (基于 DOM 的 XSS) | Client-side JavaScript | Medium–High | Entirely browser-side; server never sees the payload |

> 中文简释：反射型是一次性的（需要诱导点击），存储型是持久化的（所有访问者受害），DOM 型完全在浏览器端发生。

---

## 3. Reflected XSS: The One-Shot Attack

**Reflected XSS** arises when an application receives data in an HTTP request and includes that data within the immediate response in an unsafe way — without proper **encoding** (编码) or **escaping** (转义).

**Example — a status message page:**

```
https://example.com/status?message=All+is+well
```

The server renders:

```html
<p>Status: All is well.</p>
```

An attacker crafts a malicious URL:

```
https://example.com/status?message=<script>/*+Bad+stuff+here...+*/</script>
```

The server renders:

```html
<p>Status: <script>/* Bad stuff here... */</script></p>
```

When a victim clicks this link, the script executes in **their browser**, in the context of **their session**. The attacker typically delivers the link via phishing email, social media, or a **watering hole** (水坑攻击) site.

⚠️ **Key limitation**: The victim must interact with the crafted URL — it is not self-propagating.

> 中文简释：反射型 XSS 的载荷在 URL 中，用户点击恶意链接后，脚本在响应页面中"反射"出来并执行。攻击需要社交工程配合。

---

## 4. Stored XSS: The Persistent Threat

**Stored XSS** (also known as **persistent XSS** / 持久型 XSS or **second-order XSS** / 二阶 XSS) arises when an application receives data from an untrusted source, stores it (usually in a database), and later includes that data in HTTP responses without proper escaping.

Common injection points:
- Blog comments
- Forum posts
- User profile nicknames
- Chat room messages
- File metadata (e.g., image EXIF data)

**Example — a message board:**

Normal user submits: `<p>Hello, this is my message!</p>`

Attacker submits: `<p><script>/* Bad stuff here... */</script></p>`

Every user who views this page will execute the malicious script — **no clicking required**. This is why stored XSS is rated **Critical**: the blast radius is every user who visits the compromised page.

> 中文简释：存储型 XSS 不需要诱导点击——恶意脚本被存入数据库后，任何浏览该页面的用户都会中招，影响范围远大于反射型。

---

## 5. DOM-Based XSS: The Server Never Sees It

**DOM-based XSS** arises when **client-side JavaScript** (客户端 JavaScript) processes data from an **untrusted source** (不可信数据源) in an unsafe way, usually by writing the data back to the **DOM** (Document Object Model / 文档对象模型).

The server's response is perfectly safe — the vulnerability exists entirely in the browser's JavaScript execution.

### Sources and Sinks

DOM XSS is described as a flow from a **source** (数据源) to a **sink** (执行点):

| Source (Where data enters) | Sink (Where data is executed) |
|----------------------------|-------------------------------|
| `location.search` (URL query string) | `document.write()` |
| `location.hash` (URL fragment) | `element.innerHTML` |
| `document.referrer` | `element.outerHTML` |
| `document.cookie` | `eval()` |
| `window.name` | `setTimeout()` / `setInterval()` |
| `postMessage` data | `element.insertAdjacentHTML` |

**Example — innerHTML sink:**

```javascript
var search = document.getElementById('search').value;
var results = document.getElementById('results');
results.innerHTML = 'You searched for: ' + search;
```

If the attacker controls the input, they can inject:

```html
<img src=1 onerror='alert(document.cookie)'>
```

The `<script>` tag does **not** execute inside `innerHTML` on modern browsers — but **event handlers** (事件处理器) like `onerror` and `onload` do. This is a common misconception.

**Example — document.write sink:**

```javascript
document.write('<img src="/tracker.gif?search=' + location.search + '">');
```

Payload in URL: `?search="><script>alert(1)</script>`

The `">` closes the `<img>` tag, then the `<script>` executes. Unlike `innerHTML`, `document.write` **does** support `<script>` elements.

> 中文简释：DOM 型 XSS 的核心概念是"源→汇"：不可信数据从一个入口（如 URL）流向一个危险的执行点（如 innerHTML）。服务器日志里完全看不到攻击载荷。

---

## 6. Framework-Specific DOM XSS

### jQuery

jQuery's `attr()` function can change DOM element attributes. If data from the URL is passed to `attr()`, it can lead to XSS:

```javascript
$('#backLink').attr("href", new URLSearchParams(window.location.search).get('returnUrl'));
```

Payload: `?returnUrl=javascript:alert(document.domain)` — clicking the back link executes the script.

jQuery's `$()` **selector function** is also a dangerous sink. Classic vulnerability:

```javascript
$(window).on('hashchange', function() {
    var element = $(location.hash);
    element[0].scrollIntoView();
});
```

Payload via iframe: `<iframe src="https://vulnerable.com#" onload="this.src+='<img src=1 onerror=alert(1)>'">`

### AngularJS

When a page uses the `ng-app` attribute, AngularJS processes expressions inside `{{ }}` curly braces. This means:

```html
{{ constructor.constructor('alert(1)')() }}
```

This executes JavaScript **without any angle brackets** — even if `<` and `>` are HTML-encoded.

> 中文简释：jQuery 的 `attr()` 和 `$()` 选择器、AngularJS 的模板表达式 `{{ }}` 都是框架特有的 DOM XSS 入口，传统过滤 `<script>` 对它们无效。

---

## 7. What Can an Attacker Do with XSS?

Once the malicious script runs in the victim's browser, the attacker can:

| Action | Description |
|--------|-------------|
| **Session hijacking** (会话劫持) | Steal `document.cookie` to impersonate the user |
| **Credential capture** (凭证窃取) | Inject a fake login form and harvest passwords |
| **Keylogging** (键盘记录) | Listen for `keypress` events and exfiltrate data |
| **MFA bypass** (绕过多因素认证) | Use the existing session to approve MFA prompts |
| **CSRF bypass** (绕过 CSRF 防护) | Read CSRF tokens from the DOM and submit forged requests |
| **Cryptojacking** (加密货币挖矿) | Load a cryptocurrency mining script |
| **Defacement** (网页篡改) | Modify visible content on the page |
| **Malware delivery** (恶意软件投递) | Redirect users to exploit kits |

> 中文简释：XSS 不只是弹个 alert——会话劫持、MFA 绕过、键盘记录都是真实威胁。存储型 XSS + 管理员受害者 = 全站沦陷。

---

## 8. Prevention: A Multi-Layer Defense

### Layer 1: Output Encoding (输出编码) — The Primary Defense

Encode untrusted data based on the **output context** (输出上下文):

| Context | Encoding Method | Example |
|---------|----------------|---------|
| HTML body | HTML entity encoding (HTML 实体编码) | `<` → `&lt;` |
| HTML attribute | HTML attribute encoding | `"` → `&quot;` |
| JavaScript variable | JavaScript Unicode encoding | `'` → `\u0027` |
| URL parameter | URL encoding (URL 编码) | ` ` → `%20` |
| CSS value | CSS hex encoding | Limited; avoid if possible |

**Rule**: You cannot just HTML-encode everything and call it safe. Each context requires its own encoding. HTML entity encoding does **not** work inside `<script>` tags, `on*` event handlers, or CSS.

```java
// ✅ Using OWASP Java Encoder — context-aware encoding
import org.owasp.encoder.Encode;

// HTML body context
out.write("<p>" + Encode.forHtml(userInput) + "</p>");

// HTML attribute context
out.write("<input value='" + Encode.forHtmlAttribute(userInput) + "'>");

// JavaScript context
out.write("<script>var x = '" + Encode.forJavaScript(userInput) + "';</script>");
```

### Layer 2: Input Validation (输入验证) — Filter on Arrival

At the point where user input is received, filter as strictly as possible based on what is expected. Use **allowlists** (白名单), not blocklists.

### Layer 3: Content Security Policy (CSP / 内容安全策略) — Defense in Depth

CSP is an HTTP response header that tells the browser which sources of content are allowed:

```http
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'
```

- `default-src 'self'` — only load resources from the same origin
- `script-src 'self'` — only execute scripts from the same origin (blocks inline scripts)
- `unsafe-inline` — allows inline styles (avoid `unsafe-inline` for scripts!)

⚠️ CSP is a **mitigation**, not a fix. Many CSP implementations can be bypassed. Use it as an additional layer, not your primary defense.

### Layer 4: Trusted Types (可信类型) — Eliminating DOM XSS

On Chromium-based browsers, enable Trusted Types:

```http
Content-Security-Policy: require-trusted-types-for 'script'
```

This forces all DOM XSS sinks (`innerHTML`, `document.write`, etc.) to reject plain strings. Assignments must go through a **vetted policy** (审查策略), typically delegating to a sanitizer like DOMPurify:

```javascript
// Create a policy that sanitizes HTML
const policy = trustedTypes.createPolicy('sanitizer', {
  createHTML: (input) => DOMPurify.sanitize(input)
});

// Now this is safe — plain strings would throw an error
element.innerHTML = policy.createHTML(untrustedData);
```

Trusted Types is one of the **only controls that eliminates entire classes of DOM XSS** rather than merely mitigating them.

### Layer 5: Cookie Protection (Cookie 保护)

Set cookie flags to limit XSS impact:

```
Set-Cookie: session=abc123; HttpOnly; Secure; SameSite=Strict
```

- **HttpOnly** — prevents JavaScript from reading the cookie via `document.cookie`
- **Secure** — only sent over HTTPS
- **SameSite=Strict** — prevents the cookie from being sent in cross-site requests

### Layer 6: HTML Sanitization (HTML 净化)

When you must accept HTML from users (e.g., rich text editors), use a well-tested sanitizer:

```javascript
// ✅ DOMPurify — strips dangerous elements and attributes
element.innerHTML = DOMPurify.sanitize(userHtmlInput);
```

Never write your own sanitizer. Browser parsing quirks make this extremely dangerous.

> 中文简释：防御 XSS 是分层体系：输出编码是根本（按上下文选编码），CSP 是纵深，Trusted Types 从根源消灭 DOM XSS，HttpOnly 限制 Cookie 窃取，DOMPurify 处理必须接受的 HTML。

---

## 9. XSS vs. Other Vulnerabilities — Quick Comparison

| Dimension | XSS | SQL Injection | CSRF |
|-----------|-----|---------------|------|
| Target | Browser (other users) | Database (application data) | Application actions |
| Direction | Attacker → Victim's browser | Attacker → Application's DB | Victim → Application |
| Requires user action? | Reflected: yes; Stored: no | No | Yes |
| Primary defense | Output encoding + CSP | Parameterized queries | Anti-CSRF tokens |

> 中文简释：XSS 攻浏览器、SQLi 攻数据库、CSRF 诱骗用户操作——三种漏洞目标不同，防御手段也不同。

---

## Key Terms

| English | 中文 | Note |
|--------|------|------|
| Cross-Site Scripting (XSS) | 跨站脚本攻击 | 注入恶意 JS 到网页，在用户浏览器中执行 |
| Same-Origin Policy (SOP) | 同源策略 | 浏览器安全机制，限制跨源数据访问 |
| Reflected XSS | 反射型 XSS | 载荷在请求中"反射"回响应，需诱导点击 |
| Stored XSS / Persistent XSS | 存储型/持久型 XSS | 载荷存入数据库，所有访问者受害 |
| DOM-based XSS | 基于 DOM 的 XSS | 完全在浏览器端发生，服务器不可见 |
| Source (DOM XSS) | 数据源 | 不可信数据的入口，如 `location.search` |
| Sink (DOM XSS) | 执行点/汇 | 危险的 DOM 操作，如 `innerHTML`、`eval()` |
| Output Encoding | 输出编码 | 按上下文对不可信数据做安全转义 |
| HTML Entity Encoding | HTML 实体编码 | `<` → `&lt;` 等，用于 HTML 上下文 |
| Content Security Policy (CSP) | 内容安全策略 | HTTP 头，限制可加载的内容来源 |
| Trusted Types | 可信类型 | Chromium 特性，强制 DOM 操作经过审查策略 |
| DOMPurify | HTML 净化库 | 剥离危险 HTML 元素和属性的库 |
| HttpOnly | Cookie 只读标志 | 阻止 JavaScript 读取 Cookie |
| Event Handler | 事件处理器 | `onerror`、`onload` 等，可在 innerHTML 中执行 |
| Session Hijacking | 会话劫持 | 窃取会话 Cookie 冒充用户 |
| Watering Hole | 水坑攻击 | 在目标常访问的网站植入恶意代码 |

---

## 甲方视角思考

- 输出编码是治本方案，SDL 应按输出上下文（HTML/属性/JS/URL/CSS）强制匹配编码函数，"统一 HTML 编码"不等于安全。
- DOM XSS 是甲方最大盲区——DAST 扫描器对纯客户端漏洞覆盖率低，Trusted Types + 代码审计是目前最有效的组合。
- 存储型 XSS 优先级必须最高：评论区/个人简介/上传文件名是经典注入点，任何用户输入后"被其他用户看到"的场景都要排查。
- CSP 上线顺序：先 `Content-Security-Policy-Report-Only` 观察违规报告，确认无误后再切换到强制模式。

---

## 明日预告

**Day 14: CSRF (Cross-Site Request Forgery) — Making the Victim Do the Work**  
我们从浏览器脚本注入转向请求伪造，学习 CSRF 的攻击原理、SameSite Cookie 防御、以及 Anti-CSRF Token 的正确实现方式。
