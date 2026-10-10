---
title: "Day 4 — Password Hashing Salting"
date: 2026-07-10
tags:
  - daily
  - security
  - english
description: "Why Secure Password Storage Matters"
---

**Date: 2026-07-10**
**Difficulty: ★★☆☆☆ Conceptual**
**Source: Encryption Consulting — Password Storage Done Right: Hashing, Salting, and bcrypt vs. Argon2 vs. PBKDF2**
**Link: https://www.encryptionconsulting.com/password-storage-done-right-hashing-salting-and-bcrypt-vs-argon2-vs-pbkdf2/**

---

## 📖 Article

### Why Secure Password Storage Matters

Most people never think about how their passwords are stored after clicking "Sign Up." They just trust that companies are handling it the right way. But that trust is not always earned.

Every year, breaches expose millions of user **credentials** (凭证). In many cases, those credentials were stored in ways that made cracking them easy — no **salting** (加盐), weak **hashes** (哈希值), sometimes even **plaintext** (明文). These are not edge cases; they are recurring failures.

When attackers steal a password database, they do not instantly have everyone's passwords. What they have is a set of stored representations. If those were created properly, the data is largely useless. If not, they can recover thousands of real passwords in hours.

There is also a compliance dimension. Frameworks like **NIST SP 800-63B** (美国国家标准与技术研究院数字身份指南), **GDPR** (通用数据保护条例), and **PCI-DSS** (支付卡行业数据安全标准) all carry expectations around how authentication data is protected. Poor password storage is both a technical failure and a regulatory one.

---

### How Hashing Actually Works

A **cryptographic hash function** (密码学哈希函数) takes a password as input and produces a fixed-length output called a **hash** or **digest** (摘要). The key property: this process only goes **one way** (单向). You cannot reverse a hash to get the original password back.

```
"mypassword123" → $2b$12$LJ3m4ys3LgHJK8vQp5N6Ke...  (bcrypt output)
```

At login, the entered password is hashed and compared to what was stored. The system never needs to know the original password. 哈希的核心思想：存储时只存哈希，验证时比对哈希，原始密码永不落地。

**The trap:** general-purpose hash functions like **MD5** and **SHA-256** were built for **speed**, not for passwords. A modern GPU can compute billions of SHA-256 hashes per second. That speed is a gift to attackers running **brute-force** (暴力破解) or **dictionary attacks** (字典攻击).

| Algorithm | Hashes per GPU per second |
|---|---|
| MD5 | ~40 billion |
| SHA-256 | ~10 billion |

> ⚠️ **Never use MD5, SHA-1, or raw SHA-256 alone for password hashing.** They were not designed for this purpose.

Password hashing algorithms are deliberately designed to be **slow**, making brute-force attacks computationally expensive. 专用密码哈希算法的核心设计哲学：不是让哈希"算得快"，而是让攻击者"算不起"。

---

### Salting: Why It's Non-Negotiable

A **salt** (盐值) is a unique, randomly generated string added to each password before hashing:

```
hash("mypassword" + "x7Kp2mN9qR")  →  unique hash
hash("mypassword" + "bT4wL1fA3s")  →  completely different hash
```

Even if two users choose the same password, their salts make the resulting hashes completely different.

**What salting defeats:** **Rainbow tables** (彩虹表) — precomputed lookup tables mapping hashes back to common passwords. Without salting, an attacker can take a stolen hash and look it up in seconds. With unique salts, rainbow tables become useless; the attacker must crack each hash individually.

Salts are **not secret**. They are stored alongside the hash. Their value comes from being unique and random, not from being hidden. Salting is not encryption — it defeats **precomputation attacks** (预计算攻击).

> 💡 **Important:** bcrypt and Argon2 automatically generate and embed salts. If you're using standard libraries, salting is already handled. If you're implementing it yourself, you're probably doing it wrong — use a standard library.

---

### The Three Contenders: bcrypt, Argon2, PBKDF2

| Feature | bcrypt | Argon2id | PBKDF2 |
|---|---|---|---|
| Memory-hardness | ❌ Not memory-hard | ✅ Configurable RAM | ❌ Not memory-hard |
| Built-in salting | ✅ Automatic | ✅ Automatic | ❌ Manual |
| Parallelism control | ❌ | ✅ | ❌ |
| Password length limit | 72 bytes | No limit | No limit |
| NIST recommended | Not listed | ✅ Yes | ✅ Yes |
| GPU resistance | Moderate | **High** | Low–Moderate |
| Maturity | 25+ years | Since 2015 | Since 2000 |

#### bcrypt — The Battle-Tested Veteran

bcrypt was created in 1999 specifically for password hashing. It includes automatic salting and a configurable **cost factor** (成本因子) that controls how computationally expensive each hash is:

| Cost Factor | Time per hash |
|---|---|
| 10 | ~100 ms |
| 12 | ~400 ms |
| 14 | ~1.6 seconds |

At 400ms per hash, trying 1 billion passwords takes over 12 years — versus seconds with SHA-256.

```
$2b$12$LJ3m4ys3LgHJK8vQp5N6KeVZ2W1x9mC7TdOqKp6sY.BxCm2W5Hq
 │  │  │                                                    │
 │  │  └── 22-char salt (Base64)                            │
 │  └───── Cost factor (12)                                  │
 └──────── Algorithm version (2b) ──────────────────────────┘
```

**Limitation:** bcrypt truncates inputs beyond 72 bytes and lacks memory-hardness, making it more vulnerable to highly parallel hardware attacks (GPU/FPGA clusters).

#### Argon2 — The Modern Standard

Argon2 won the **Password Hashing Competition** (密码哈希竞赛) in 2015 and is recommended by NIST in SP 800-63B. Three variants exist:

- **Argon2d** — resists GPU attacks
- **Argon2i** — resists **side-channel attacks** (侧信道攻击)
- **Argon2id** — combines both; **recommended for password storage**

What sets Argon2 apart is **memory-hardness** (内存硬度). It requires a configurable amount of RAM during computation. GPUs have thousands of cores but limited memory per core — Argon2 forces each attempt to consume significant RAM, dramatically reducing how many attempts can run in parallel.

**OWASP-recommended parameters:** at least 19 MiB memory, 2 iterations, 1 degree of parallelism. Adjust upward based on your server capacity.

#### PBKDF2 — The Compliance Option

PBKDF2 is the oldest of the three and widely used in **FIPS 140-2 / 140-3** (联邦信息处理标准) validated environments because it's built on approved HMAC constructions. If your organization requires FIPS compliance (common in federal and regulated financial sectors), PBKDF2 with SHA-256 or SHA-512 may be required.

**Weakness:** It lacks memory-hardness. Compensate with a high **iteration count** (迭代次数) — NIST recommends at least **600,000 iterations** with HMAC-SHA-256.

---

### Best Practices Checklist

| # | Practice | Why |
|---|---|---|
| 1 | Use **Argon2id** for new systems | Memory-hard + NIST-recommended |
| 2 | Keep **bcrypt** at cost factor ≥ 12 for legacy | Still solid; 25 years battle-tested |
| 3 | PBKDF2 **only** when FIPS compliance requires it | Weakest of the three |
| 4 | Always use **unique, random salts** | Defeats rainbow tables |
| 5 | Enforce **minimum 12 characters** | Length > complexity |
| 6 | Check passwords against **breached password lists** | Blocks "Password123!" |
| 7 | Implement **rate limiting** on login attempts | Slows brute-force |
| 8 | Require **MFA** (多因素认证) for sensitive accounts | Last line of defense |
| 9 | Hash **server-side**, not client-side | Client hashing can be bypassed |
| 10 | Plan for **algorithm migration** — re-hash at next login | No forced mass password resets |

---

### Password Policy: What NIST Actually Says

Based on **NIST SP 800-63B** (updated 2024):

**✅ DO:**
- Require minimum 8 characters (12+ recommended)
- Allow up to 64+ characters, all printable characters including spaces and Unicode
- Check against known breached password lists
- Allow paste in password fields (encourages password managers)

**❌ DON'T:**
- Don't require periodic password changes — this leads to weaker passwords (users append "1", "2", "3")
- Don't require specific character classes — "Must contain uppercase, lowercase, digit, symbol" produces "Password1!"
- Don't use security questions — easily searched or guessed
- Don't truncate passwords — hash all characters the user typed

> **Mindset shift:** "correct horse battery staple" is far stronger than "P@ssw0rd!" and easier to remember. 长度战胜复杂度。

---

## 📌 甲方安全工程师视角 (Security Engineer's Perspective)

1. **审计内部系统密码存储方案** — 扫一遍是否还有 MD5/SHA-1/明文存储，这是安全基线中最不该出现的技术债。
2. **bcrypt cost factor < 10 的系统等同于裸奔** — 趁还没出事，推进算法升级或在下次登录时触发 re-hash 迁移。
3. **NIST 说不要强制定期改密** — 把这篇文章转发给还在推"90 天改密"策略的合规同事，有理有据。

---

## 🧠 Key Terms

| English | 中文 | Note |
|---|---|---|
| Hash / Digest | 哈希值 / 摘要 | Fixed-length, one-way output |
| Salt | 盐值 | Random string added before hashing |
| Plaintext | 明文 | Unencrypted, readable data |
| Credential | 凭证 | Username + password pair |
| Rainbow Table | 彩虹表 | Precomputed hash-to-password lookup |
| Brute-force Attack | 暴力破解 | Trying every possible combination |
| Dictionary Attack | 字典攻击 | Trying known/common passwords |
| Cost Factor / Work Factor | 成本因子 / 工作因子 | Controls bcrypt hash slowness |
| Memory-hardness | 内存硬度 | Requires significant RAM to compute |
| Side-channel Attack | 侧信道攻击 | Exploiting physical implementation leaks |
| NIST SP 800-63B | 美国NIST数字身份指南 | Authoritative password policy standard |
| FIPS 140-2/140-3 | 联邦信息处理标准 | US gov crypto module requirements |
| MFA | 多因素认证 | Multi-Factor Authentication |
| Precomputation Attack | 预计算攻击 | Rainbow tables are the classic example |
| Password Manager | 密码管理器 | Generates and stores strong unique passwords |
| Iteration Count | 迭代次数 | PBKDF2's equivalent of cost factor |
| Re-hash | 重新哈希 | Upgrade algorithm at next login |

---

## 🎯 Tomorrow's Preview

**Day 5 — Zero Trust Architecture: "Never Trust, Always Verify"** (★★☆☆☆)

> From perimeter-based security to identity-centric defense — what Zero Trust actually means and the core components (micro-segmentation, continuous verification, least privilege).
