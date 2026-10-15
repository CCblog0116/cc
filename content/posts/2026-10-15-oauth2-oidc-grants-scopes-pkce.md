---
title: "2026-10-15 — OAuth 2.0 and OIDC In Depth: Grants, Scopes, PKCE, and Redirect-URI Pitfalls"
date: 2026-10-15
tags:
  - daily
  - security
  - english
  - oauth
  - oidc
  - identity
description: OAuth 2.0 管授权委托、OIDC 管身份认证——授权码流程 + state + PKCE + 精确匹配 redirect_uri 构成安全基线。
---

> [!abstract] TL;DR
> OAuth 2.0 delegates "what this app may do" while OIDC asserts "who this user is" — secure implementations require the authorization code flow with PKCE, exact redirect_uri matching, narrow scopes, and full ID token validation.

## Original Article

OAuth 2.0 is a delegation protocol: it answers "may this application act on my behalf?" OpenID Connect (OIDC) is an identity layer built on top of it, answering "who is this user?" Confusing the two is the root of most OAuth security incidents. OAuth issues access tokens for API access; OIDC issues an ID token — a signed JWT asserting the user's identity. Accepting an access token as proof of login is a classic vulnerability.

For server-side web applications, the authorization code grant is the only recommended flow. The user's browser receives a short-lived, single-use authorization code, while the actual tokens are delivered directly to the backend — invisible to browser history, extensions, and Referer leaks. Three defenses form the baseline: a random per-request `state` parameter blocks CSRF on the login flow; PKCE (Proof Key for Code Exchange) ensures an intercepted code is useless without the `code_verifier`, and is now mandatory for SPAs and mobile clients; and codes should expire within 30–60 seconds and be single-use, with replay triggering revocation.

Scopes define the permission granularity of OAuth. Two rules protect the service owner: issue the narrowest scope the user consented to (e.g. `patient:reports:read`, not `read:all`), and enforce scopes at the resource server — a scope claim is advisory unless the API checks it. Audience restriction matters equally: a token minted for API-A must be rejected by API-B.

The single most dangerous OAuth bug class is broken `redirect_uri` validation. The authorization server must match it exactly — never by prefix or wildcard. Otherwise an attacker can steer the redirect and turn the application into a token relay: the victim's authorization code lands on `attacker.com` and is exchanged for tokens. Common mistakes include prefix matching (`https://app.com.evilsite.com` passes), path traversal, open redirector chains, and subdomain wildcards that turn a compromised dev subdomain into a code collector.

On the OIDC side, three checks are mandatory in the client: verify the ID token's signature against the IdP's JWKS; verify the `iss`, `aud`, and `exp` claims exactly; and verify the `nonce` sent in the authorization request — this defends against replay and token substitution. The implicit flow, which returns tokens in the URL fragment, is deprecated by OAuth 2.1 for browser apps.

Finally, token storage and lifecycle close the loop. Browser tokens belong in httpOnly, Secure, SameSite cookies — never localStorage, where XSS can exfiltrate them. Refresh tokens must be rotated with reuse detection, and logout must revoke refresh tokens server-side, not merely clear a cookie.

Source: [RFC 6749 — The OAuth 2.0 Authorization Framework](https://www.rfc-editor.org/rfc/rfc6749) · [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html) · [PortSwigger — OAuth 2.0 authentication vulnerabilities](https://portswigger.net/web-security/oauth)

## Key Vocabulary

| Word | Meaning | 中文 |
| ---- | ------- | ---- |
| delegation protocol | a protocol that lets an app act on the user's behalf | 委托授权协议 |
| authorization code grant | the recommended OAuth flow for server-side web apps | 授权码授权 |
| access token | credential used to call APIs, not proof of login | 访问令牌 |
| ID token | signed JWT asserting the user's identity | 身份令牌 |
| PKCE (Proof Key for Code Exchange) | binds the token exchange to the original requester | 授权码交换密钥证明 |
| scope | permission granularity of an OAuth grant | 作用域 |
| audience restriction | a token must only be accepted by its intended API | 受众限制 |
| redirect_uri validation | exact matching of the post-login redirect target | 重定向地址校验 |
| nonce | one-time random value preventing ID token replay | 一次性随机数 |
| JWKS (JSON Web Key Set) | the IdP's public key set for signature verification | JSON Web 密钥集合 |
| refresh token rotation | issuing a new refresh token per use, revoking on reuse | 刷新令牌轮换 |
| token relay | attack where a lax redirect_uri leaks the auth code | 令牌中继 |

## Sentence Patterns

1. **"X is a … that answers '…?', while Y answers '…?'"** — 用对比定义两个易混概念。
   - *OAuth answers "may this app act on my behalf?", while OIDC answers "who is this user?"*

2. **"Even if A is intercepted, it is useless without B."** — 描述纵深防御机制的价值。
   - *Even if the authorization code is intercepted, it is useless without the code_verifier.*

3. **"X is advisory unless Y checks it."** — 强调"声明"与"强制执行"的区别。
   - *A token's scope claim is advisory unless the resource server checks it.*

4. **"must match X exactly, not by prefix or wildcard"** — 描述严格校验要求。
   - *The authorization server must match the redirect_uri exactly, not by prefix or wildcard.*

5. **"X closes the loop"** — 表示某机制补齐了完整的安全生命周期。
   - *Token revocation and introspection endpoints close the loop.*

## 中文摘要

OAuth 2.0 负责授权委托（应用能做什么），OIDC 在其上提供身份认证（用户是谁），混淆二者是多数 OAuth 事件的根源。安全基线：授权码流程 + state 防 CSRF + PKCE 防授权码拦截 + redirect_uri 精确匹配；签发端最小化 scope、资源端强制校验受众；ID token 必验签名、iss/aud/exp 与 nonce；浏览器令牌只放 httpOnly Cookie，refresh token 轮换并在登出时服务端吊销。
