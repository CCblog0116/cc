---
title: "Day 19 — Identification and Authentication Failures: When the Front Door Lock Fails"
date: 2026-09-01
tags:
  - daily
  - security
  - english
description: "If the network perimeter is the fence around a house, authentication （身份认证） is the front door lock. It does not matter how thick the walls are if an a"
---

**Date:** 2026-09-01 | **Difficulty:** ★★☆☆☆ Conceptual | **Source:** OWASP Top 10:2021 A07 | **Link:** [OWASP A07:2021](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)

---

## Why This Matters

If the network perimeter is the fence around a house, **authentication** （身份认证） is the front door lock. It does not matter how thick the walls are if an attacker can simply turn the key — or pick the lock. OWASP ranks **identification and authentication failures** as the **#7 risk** in its 2021 Top 10, and it is one of the oldest and most exploited categories in web application security.

This category covers any weakness that allows an attacker to impersonate a legitimate user. The 2024 Verizon DBIR found that **49% of breaches involve stolen credentials** （被盗凭证）, making credential-based attacks the single most common initial access vector. Attackers do not always need sophisticated exploits; sometimes they just need a weak password, a leaked database, or a session token that never expires.

> 身份认证失败是企业攻防战中最常见的突破口之一：凭证窃取、弱口令、会话管理不当，往往比 0-day 更频繁地导致失陷。

---

## What Counts as an Authentication Failure?

OWASP A07 groups together a wide set of weaknesses. You have an authentication problem if your application does any of the following:

- Permits **automated attacks** such as **credential stuffing** （凭证填充）, where attackers use leaked username-password pairs from other breaches to log in.
- Allows **brute-force** （暴力破解） or other **guessing attacks** against weak or common passwords.
- Uses **plain text** or **weakly hashed passwords** that can be cracked quickly if the database leaks.
- Implements **weak or missing MFA** （多因素认证）, making a single stolen password enough for full account takeover.
- Exposes **session IDs** （会话标识） in URLs, or accepts predictable, reused, or never-expiring session tokens.
- Fails to **invalidate sessions** after logout, password change, or prolonged inactivity.
- Does not properly rotate or protect **authentication tokens** and **API keys**.

A useful way to think about it: authentication is not a single gate. It is a **lifecycle** — from registration and login to session use, logout, and credential recovery. A failure at any stage breaks the chain.

> 认证不是一次性检查，而是贯穿注册、登录、会话、登出、找回密码整个生命周期的连续过程。

---

## Common Attack Patterns

### 1. Credential Stuffing: Reusing the Internet's Passwords

When a website is breached, attackers sell or publish millions of username-password pairs. Other attackers then automate login attempts on thousands of sites using those same credentials. Because people reuse passwords, the success rate is low but the payoff is massive at scale. A 1% hit rate against one million accounts means 10,000 compromised accounts.

Tools like **Open Bullet**, **Sentry MBA**, and cloud-based **proxy rotation services** make credential stuffing cheap and hard to block with simple IP-based rate limiting.

> 凭证填充攻击靠的不是猜你的密码，而是赌你在多个网站用了同一套密码。

### 2. Brute Force and Password Guessing

If an application has no **rate limiting** （速率限制） or **account lockout** （账户锁定）, attackers can systematically guess passwords. They do not guess randomly; they use dictionaries of common passwords (`password123`, `Qwerty123`, company names plus seasons) and lists tailored to the target's language and culture.

A modern GPU can test billions of hashes per second for weak algorithms like **MD5** or **SHA-1**. Even salted MD5 is often crackable in minutes for common passwords.

> 没有速率限制和账户锁定的登录接口，本质上就是在邀请自动化工具来试密码。

### 3. Session Hijacking and Fixation

After a successful login, the server gives the browser a **session cookie** （会话 Cookie）. If that cookie is predictable, exposed over HTTP, never expires, or not bound to the user's IP and device, an attacker can steal or guess it.

- **Session hijacking** （会话劫持）: stealing a valid cookie via XSS, network sniffing, or malware.
- **Session fixation** （会话固定）: forcing a user to use a session ID chosen by the attacker, then waiting for them to authenticate.

Without the `HttpOnly`, `Secure`, and `SameSite` flags, a session cookie is far easier to steal or misuse.

> 会话 Cookie 的保护质量，直接决定了攻击者拿到密码之外是否还能"借壳登录"。

### 4. Weak MFA and Recovery Flows

MFA is powerful, but only when implemented well. Common bypass techniques include:

- **SIM swapping** （SIM 卡 swapping） to intercept SMS codes.
- Phishing the user into entering both password and **TOTP** （基于时间的一次性密码） on a fake site.
- Abusing weak "recovery codes" or knowledge-based questions.
- Exploiting inconsistent MFA enforcement across subdomains or API endpoints.

> MFA 不是万能药；SMS 验证码可被运营商侧攻击截获，钓鱼也能骗取 TOTP。

---

## Defense: Building Trust into Every Login

OWASP provides a clear checklist for fixing authentication failures:

| Control | What to Do | Why It Helps |
|---------|-----------|--------------|
| **Strong password policy** | Require length (≥12 chars), block common passwords, and do not force arbitrary rotation | Long, unique passwords resist guessing and cracking |
| **Rate limiting + lockout** | Slow down repeated failures; use **CAPTCHA** only as a last resort | Blocks automated brute-force and stuffing attacks |
| **Multi-factor authentication** | Enforce MFA for privileged users and high-risk actions | Raises the bar even if the password is stolen |
| **Secure session management** | Use long random session IDs, set short idle timeouts, rotate on privilege change | Limits the window if a session token is stolen |
| **Secure cookie flags** | `HttpOnly`, `Secure`, `SameSite=Strict` | Prevents XSS/network theft and CSRF misuse |
| **Credential breach monitoring** | Check new passwords against **HIBP** （Have I Been Pwned） or similar leaked-password APIs | Stops users from registering already-leaked passwords |
| **Centralized identity provider** | Use a hardened **IdP** （身份提供方） like Entra ID, Okta, or Keycloak | Reduces duplicated auth logic and misconfiguration risk |

A mature organization treats authentication as a **service**, not a feature. Rolling your own login system is possible, but it is also one of the fastest ways to introduce subtle, high-impact vulnerabilities.

> 对甲方而言，认证最好是交给经过充分验证的身份提供方，而不是每个业务系统各自重复造轮子。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Identification and Authentication Failures | 身份识别与认证失败 | OWASP Top 10 A07:2021 |
| Authentication | 身份认证 | 验证"你是不是你" |
| Session ID | 会话标识 | 服务器识别已登录用户的令牌 |
| Session Cookie | 会话 Cookie | 浏览器保存的会话标识载体 |
| Credential Stuffing | 凭证填充 | 用泄露的用户名/密码批量尝试登录 |
| Brute Force | 暴力破解 | 系统化尝试大量密码 |
| Rate Limiting | 速率限制 | 限制单位时间内的请求次数 |
| Account Lockout | 账户锁定 | 失败多次后暂时禁用账户 |
| Multi-Factor Authentication (MFA) | 多因素认证 | 两种及以上不同类别因素的认证 |
| TOTP (Time-based One-Time Password) | 基于时间的一次性密码 | 常见如 Google Authenticator 生成的 6 位码 |
| Session Hijacking | 会话劫持 | 盗取有效会话标识以冒充用户 |
| Session Fixation | 会话固定 | 攻击者预先设置会话 ID 并诱导用户认证 |
| HttpOnly / Secure / SameSite | Cookie 安全属性 | 防止 XSS 窃取、强制 HTTPS、限制跨站发送 |
| Identity Provider (IdP) | 身份提供方 | 如 Entra ID、Okta、Keycloak |
| Have I Been Pwned (HIBP) | 泄露凭证查询服务 | 可查询密码是否在公开泄露数据库中 |

---

## 甲方视角思考

1. **MFA 全覆盖是最高性价比的防线** — 先推管理员、VPN、邮箱、核心系统的 MFA，比修复一百个配置漏洞更能直接降低账户失陷风险。
2. **登录接口必须做速率限制和失败监控** — 不仅要限流，还要记录异常登录模式并联动态势感知或 SOAR 自动告警/封禁。
3. **会话策略要统一且严格** — 统一过期时间、强制 Idle Timeout、密码修改/权限变更后强制重新认证，避免各业务系统规则不一。
4. **采购系统要核查 IdP 集成能力** — 新业务系统优先接入统一身份认证，杜绝"每个系统一套密码"的历史债务继续累积。

---

## Tomorrow — Day 20 Preview

**Software and Data Integrity Failures (OWASP A08)** — why trusting your own update channel is dangerous, how **supply chain** and **CI/CD pipeline** attacks work, and what **code signing**, **SLSA**, and **immutable build artifacts** mean for enterprise defenders.
