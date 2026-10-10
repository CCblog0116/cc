---
title: "Day 29 — JWT Attacks: When 'Trust' Becomes a Weapon"
date: 2026-09-14
tags:
  - daily
  - security
  - english
description: "⭐ Difficulty: ★★★☆☆ Technical"
---

📅 **Date:** September 14, 2026  
⭐ **Difficulty:** ★★★☆☆ Technical  
📰 **Source:** PortSwigger Web Security Academy + OWASP JWT Security Cheat Sheet + RFC 7519  
🔗 **Reference:** [https://portswigger.net/web-security/jwt](https://portswigger.net/web-security/jwt)

---

## 1. What Is a JWT?

A **JSON Web Token (JWT)** is a compact, URL-safe token format used to carry claims (assertions about a user or session) between two parties. It consists of three parts separated by dots: **Header**（头部）, **Payload**（载荷）, and **Signature**（签名）.

The structure looks like this:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoiYWRtaW4iLCJyb2xlIjoiYWRtaW4ifQ.xxx...
```

Each part is **Base64URL-encoded**（Base64URL 编码）. Decoding the header reveals the algorithm (`alg`) and token type (`typ`). Decoding the payload reveals the claims. The signature is computed using the algorithm and a secret key (for symmetric algorithms like **HS256** — HMAC with SHA-256) or a private key (for asymmetric algorithms like **RS256** — RSA with SHA-256).

JWTs are widely used in **Single Sign-On (SSO)**（单点登录）, **API authentication**（API 认证）, and **session management**（会话管理）. Because the server can verify the signature without querying a database, JWTs are stateless and scalable — but that same property makes them dangerous if the verification logic is flawed.

---

## 2. The "alg": "none" Attack

The simplest and most devastating JWT attack is changing the algorithm header to `"alg": "none"`.

By design, some JWT libraries support an **unsecured JWT**（无签名 JWT） mode where the signature is omitted entirely. If the server accepts `"alg": "none"` and skips signature verification, an attacker can forge any payload they want.

**Attack flow:**
1. Decode the original JWT header and change `"alg": "RS256"` → `"alg": "none"`.
2. Modify the payload (e.g., change `"role": "user"` → `"role": "admin"`).
3. Re-encode header + payload with Base64URL, omit the signature, and send.

If the server trusts the `alg` field from the client, it will skip verification entirely. This is a **authentication bypass**（认证绕过） and often leads to **privilege escalation**（权限提升）.

> ⚠️ 甲方视角提醒：在 SSO 接口（如 `/km-platform-web/ssologin/checkLoginUser`）中，若后端使用了第三方 JWT 库且未禁用 `none` 算法，攻击者可直接伪造管理员身份令牌。

**Defense:**
- Reject tokens with `"alg": "none"` at the application level.
- Use a **whitelist**（白名单） of permitted algorithms and ignore the `alg` header from the token.
- Example (Python with `PyJWT`):

```python
import jwt

# BAD: trusts the token's alg header
# jwt.decode(token, key, algorithms=["HS256", "RS256", "none"])

# GOOD: whitelist only the expected algorithm
jwt.decode(token, key, algorithms=["HS256"])  # never include "none"
```

---

## 3. Algorithm Confusion: HS256 / RS256 Key Confusion

This attack exploits a subtle behavior in JWT libraries. **RS256**（RSA Signature） uses a private key to sign and a **public key**（公钥） to verify. **HS256**（HMAC Signature） uses the same secret key for both signing and verification.

If an application expects RS256 but the attacker supplies a token signed with HS256 using the **public key as the HMAC secret**（公钥作为 HMAC 密钥）, some vulnerable libraries will accept it.

**Why it works:**
- The server has the public key available (often exposed via a **JWKS endpoint** — JSON Web Key Set 端点).
- The attacker downloads the public key, signs a forged JWT with HS256 using that public key as the secret, and sets `"alg": "HS256"`.
- If the library blindly switches to HMAC verification using whatever key it has, the forgery validates.

**Defense:**
- Hardcode the expected algorithm; never switch algorithms based on the token header.
- Keep public keys in a format that cannot be used as an HMAC secret (e.g., RSA key objects, not raw strings).
- Separate key stores for symmetric and asymmetric operations.

---

## 4. Weak Secret / Brute-Force Attacks on HS256

When HS256 is used, the security of the entire token depends on the strength of the secret key. If the secret is short, predictable, or hardcoded in source code, an attacker can **brute-force**（暴力破解） or **dictionary-attack**（字典攻击） it offline.

Tools like **hashcat** and **jwt_tool** can test millions of candidate secrets per second against an HMAC-SHA256 signature. A secret like `secret123` can be cracked in seconds.

**Defense:**
- Use a cryptographically random secret of at least 256 bits (32 bytes).
- Rotate secrets regularly via a **Key Management Service (KMS)**（密钥管理服务）.
- Never hardcode JWT secrets in repositories; use environment variables or secret vaults.

---

## 5. JKU / JWK Header Injection

JWT headers can include optional fields that point to external keys:

- **`jku` (JWK Set URL):** A URL where the server fetches the verification key.
- **`jwk` (JSON Web Key):** The verification key embedded directly in the header.

If the server fetches keys from user-controlled URLs or accepts inline JWKs without validation, an attacker can host their own key pair and sign forged tokens.

**Attack flow:**
1. Attacker generates an RSA key pair.
2. Hosts the public key at `https://attacker.com/jwks.json`.
3. Creates a JWT with `"jku": "https://attacker.com/jwks.json"` and signs it with their private key.
4. Server fetches the attacker's public key and verifies the signature successfully.

This is a form of **SSRF**（Server-Side Request Forgery，服务器端请求伪造） combined with authentication bypass.

**Defense:**
- Ignore `jku` and `jwk` headers entirely; use a statically configured key or a trusted **Identity Provider (IdP)**（身份提供商）.
- If dynamic key resolution is required, validate the URL against a strict whitelist and enforce TLS.

---

## 6. `kid` (Key ID) Path Traversal

The `kid` header identifies which key was used to sign the token. Some implementations use the `kid` value to construct a file path on disk to load the verification key.

If `kid` is not sanitized, an attacker can set:

```json
"kid": "../../../dev/null"
```

Or point to a known file whose contents are predictable (e.g., `/proc/self/environ`, `/etc/passwd`). If the file content is then used as the HMAC secret, the attacker may know or control the secret.

**Defense:**
- Map `kid` values to keys via an in-memory dictionary, not filesystem paths.
- Validate `kid` against a strict allowlist of known identifiers.

---

## 7. General Defense Checklist for JWT

| Control | Implementation |
|---------|---------------|
| Algorithm whitelist | Accept only the expected `alg`; reject `none` |
| Key separation | Never use a public key as an HMAC secret |
| Strong secrets | ≥256-bit random for HS256; rotate regularly |
| Ignore `jku`/`jwk` | Use static or IdP-managed keys only |
| Validate `kid` | Map to known keys, never filesystem paths |
| Token expiration | Short `exp` (expiration，过期时间); enforce `nbf` (not before) and `iat` (issued at) |
| Token binding | Bind JWT to TLS session or client certificate where possible |
| Log anomalies | Alert on algorithm changes, expired tokens, or signature failures |

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| JWT (JSON Web Token) | JSON 网络令牌 | Compact token format with header, payload, signature |
| alg | 算法 | Header field specifying signature algorithm |
| HS256 | HMAC-SHA256 签名 | Symmetric signing; same key for sign/verify |
| RS256 | RSA-SHA256 签名 | Asymmetric signing; private key signs, public key verifies |
| alg:none attack | 无算法攻击 | Forging tokens by setting alg to "none" |
| Algorithm confusion | 算法混淆攻击 | Tricking server to verify RS256 token with HS256 using public key |
| JKU (JWK Set URL) | JWK 集合 URL | External URL for fetching verification keys |
| JWK (JSON Web Key) | JSON 网络密钥 | Embedded key in JWT header |
| kid (Key ID) | 密钥标识符 | Identifies which key signed the token |
| JWKS (JSON Web Key Set) | JSON 网络密钥集 | Set of public keys exposed by IdP |
| Base64URL encoding | Base64URL 编码 | URL-safe variant of Base64 used in JWT parts |
| Payload / Claims | 载荷 / 声明 | The data carried inside the JWT |
| Signature verification | 签名验证 | Cryptographic check ensuring token integrity |
| Symmetric key | 对称密钥 | Same key for encryption/signing and decryption/verification |
| Asymmetric key | 非对称密钥 | Public/private key pair |
| Authentication bypass | 认证绕过 | Gaining access without valid credentials |
| Privilege escalation | 权限提升 | Elevating from low-privilege to high-privilege role |
| Key rotation | 密钥轮换 | Periodically replacing cryptographic keys |
| Token expiration (exp) | 令牌过期时间 | Timestamp after which the token is invalid |

---

## 甲方视角思考

- **SSO 接口审计**：检查公司 SSO 登录接口及所有依赖 JWT 的内部系统，确认是否禁用了 `none` 算法，并验证 `alg` 是否硬编码为预期值。  
- **公钥泄露风险**：若系统使用 RS256，评估公钥是否可通过 JWKS 端点被未授权访问，防止攻击者下载后用于算法混淆攻击。  
- **密钥管理**：排查代码仓库和配置文件中是否存在硬编码 JWT Secret，推动接入 KMS 或 HashiCorp Vault 实现密钥集中管理和自动轮换。  
- **WAF / SIP 检测规则**：在流量探针和 WAF 上配置 JWT 异常检测策略，如 `alg:none`、`jku` 外联请求、`kid` 包含路径遍历特征等告警规则。  

---

## Tomorrow's Preview — Day 30

**Topic:** API Security Best Practices  
**What to expect:** We'll step back from specific vulnerabilities and look at the bigger picture of securing REST/GraphQL APIs — from **rate limiting**（速率限制） and **input validation**（输入验证） to **OAuth 2.0 / OIDC** 流程安全、**API versioning** 安全策略，以及 **API Gateway**（API 网关）上的统一安全管控。作为甲方，如何对内外部 API 做安全基线检查和持续监控？Day 30 为你梳理一套可落地的 API 安全框架。
