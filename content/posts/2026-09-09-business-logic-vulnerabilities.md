---
title: "Day 26 — Business Logic Vulnerabilities: The Bugs Scanners Cannot Find"
date: 2026-09-09
tags:
  - daily
  - security
  - english
description: "In 2020, a customer of a major Chinese e-commerce platform discovered they could buy a single piece of high-end equipment for negative quantities （负数量"
---

**Date:** 2026-09-09 | **Difficulty:** ★★★☆☆ Technical | **Source:** OWASP Top 10:2021 A04 — Insecure Design / PortSwigger Web Security Academy | **Link:** [OWASP A04:2021 — Insecure Design](https://owasp.org/Top10/A04_2021-Insecure_Design/), [PortSwigger Business Logic Vulnerabilities](https://portswigger.net/web-security/logic-flaws)

---

## Why This Matters

In 2020, a customer of a major Chinese e-commerce platform discovered they could buy a single piece of high-end equipment for **negative quantities** （负数量）. By submitting `-1` as the quantity, the system calculated a *negative* total and credited the difference back to the user's stored-value account. Within hours, automated scripts had extracted over ¥800,000 in stored value before the platform patched the checkout flow.

This is a textbook **business logic vulnerability** （业务逻辑漏洞） — an error in the application's workflow that produces unintended, exploitable behaviour. Unlike SQL injection or XSS, logic flaws are invisible to automated scanners: the code does what the developer wrote, but what the developer wrote does not match what the business actually intended.

> 业务逻辑漏洞不会被扫描器发现——因为代码"完全按设计运行"，只是设计本身就错了。

---

## What Is a Business Logic Vulnerability?

A **business logic vulnerability** （业务流程漏洞） — also called a **logic flaw** or **business rule bypass** — is a defect where the application's workflow fails to enforce an intended business constraint. The attacker does not need to inject special characters, escape a sandbox, or exploit a parser. They simply *use the application correctly* in a way that no one anticipated.

These flaws are catalogued in:

- **CWE-840**: Business Logic Errors
- **CWE-1220**: Insufficient Granularity of Access Control
- **CWE-799**: Improper Control of Interaction Frequency

In the OWASP Top 10:2021, they fall under **A04: Insecure Design** — meaning the *design* lacked a control that should have been there from the start. Patches are usually code-level (adding missing checks) but the root cause is the design phase.

The defining signal: **the application's behaviour contradicts the documented business rule.**

> 业务逻辑漏洞的判定标准：应用程序的行为与业务规则不一致——即使每行代码都"按预期"运行。

---

## Six Categories of Logic Flaws

Below are the most common patterns encountered in **red team engagements** （红队演练） and bug bounties.

### 1. Missing Rate Limiting (Brute Force of Business Endpoints)

The application protects the *login* form against brute force but forgets to apply the same limit to the **coupon redemption** endpoint, the **gift card validation** endpoint, or the **password reset confirmation** endpoint.

```http
POST /api/coupons/redeem
Content-Type: application/json

{"code": "GIFT-2026"}
```

An attacker writes a 10-line script that tries 50,000 alphanumeric codes per second. The endpoint validates codes with high speed and no CAPTCHA, and the response distinguishes "invalid" from "expired" vs "already redeemed" — leaking which codes *exist*.

> 登录框做了限流，但优惠券核销、礼品卡验证、密码重置确认经常被遗漏。

### 2. Negative Quantities and Price Manipulation

E-commerce and financial apps calculate totals assuming quantity and price are always positive. When the assumption is violated, totals go negative:

```json
{
  "items": [
    {"sku": "RTX-4090", "qty": 1, "price": 12999.00},
    {"sku": "VOUCHER", "qty": -1, "price": 5000.00}
  ]
}
```

If the client sends the cart directly, and the server does not validate `qty > 0`, the server may trust the client, compute a total of ¥7,999, and ship the GPU while the voucher "refund" credits the attacker's wallet. Some platforms cache the price on the client side — an attacker changes the price to ¥0.01, the server reads it back, and the order completes at a discount that no payment provider authorised.

> 价格、数量字段如果由客户端传入且无服务端校验，等于把订单权限交给了攻击者。

### 3. Coupon Stacking and Reuse

A platform issues one coupon per user. The developer enforces this in the JavaScript front-end:

```javascript
if (usedCoupons.has(code)) throw new Error("Already used");
usedCoupons.add(code);
submit(code);
```

But the API endpoint has no server-side check. An attacker replays the same coupon across parallel requests before the local state is updated — or simply bypasses the front-end and POSTs directly to the API:

```bash
curl -X POST https://shop.example.com/api/checkout/coupon \
  -H "Authorization: Bearer ..." \
  -d '{"coupons":["SAVE20","SAVE20","SAVE20"]}'
```

If the server applies them as a list, three discounts of 20% compound — a 49% effective discount instead of the intended 20%.

> 优惠规则只能由服务端在数据库层强制——任何前端校验都是可绕过的装饰。

### 4. Race Conditions in Financial Transactions

Classic **TOCTOU** （Time-Of-Check to Time-Of-Use，检查时间与使用时间的时间差） vulnerability in money transfers:

```
Thread 1 (attacker): balance = 1000, transfer 800 → balance becomes 200
Thread 1 (attacker): balance = 200,  transfer 800 → balance becomes -600
```

If the bank reads the balance, checks for sufficient funds, then deducts, with no atomic transaction — and the attacker submits the second request *between* the check and the deduction — both transfers succeed, draining the account into negative balance. The same pattern affects **gift card redemption**, **inventory deduction**, and **referral bonus payouts**.

The fix is **atomic operations** （原子操作）: row-level locks, database transactions with `SERIALIZABLE` isolation, or distributed locks via Redis (`SETNX`).

> 转账、扣库存、发券涉及金额变动，必须用数据库事务或分布式锁——任何"先查后改"的流程都会被并发击穿。

### 5. Workflow State Violations

Many apps model business processes as **state machines** （状态机）:

```
Draft → Submitted → Approved → Paid → Delivered
```

A **workflow bypass** （流程绕过） happens when an attacker skips one or more states. For instance, jumping straight from `Draft` to `Delivered` by sending a custom POST:

```http
POST /api/order/12345/status
Content-Type: application/json
{"status": "delivered"}
```

If the server does not verify the *previous* state, the attacker receives goods marked as "delivered" before payment is recorded. Similar flaws appear in **KYC skip** （跳过实名认证）, **multi-step approval bypass**, and **2FA step skipping** (jumping from "username/password" to "logged in" without validating the OTP).

### 6. Trusted-Client Assumptions

The developer assumes certain values cannot be changed because they are "hidden" in the UI:

| Hidden Field | What Attacker Sends | Impact |
|--------------|---------------------|--------|
| `<input type="hidden" name="role" value="user">` | `role=admin` | Privilege escalation |
| `<input type="hidden" name="price" value="99.00">` | `price=0.99` | Discount abuse |
| Cookie `is_premium=0` | Cookie set to `1` | Feature unlock |
| JWT claim `user_id=42` | `user_id=1` (admin) | Account takeover |

This is the **never-trust-the-client** （永远不信任客户端） principle — every value reaching a server-side decision point must be re-validated, ideally re-loaded from the database using only the authenticated identity.

> 隐藏字段、Cookie、请求体里的角色/价格/ID 都不能直接当作权威——所有决策必须回到数据库重新查一次。

---

## Why Scanners Miss Logic Flaws

Automated tools, including **SAST** （静态应用安全测试）, **DAST** （动态应用安全测试）, and **IAST** （交互式应用安全测试）, focus on syntactic and semantic patterns:

- Does the code contain `eval()`?
- Is user input concatenated into SQL?
- Are JWT signatures verified?

None of these checks can answer: *"Did the developer forget a rate limit on the coupon endpoint?"* or *"Does the workflow allow skipping the approval step?"* Logic flaws require a human — or an AI-driven reasoning agent — to **understand the intended business process** and **devise an alternative path**.

Penetration testers call these **"the bugs that take ten minutes to find and ten hours to confirm"** — they are cheap to exploit, hard to detect, and frequently high-impact.

> 自动扫描器找的是"代码怎么错"，业务逻辑漏洞找的是"流程怎么错"——后者必须靠人脑理解业务。

---

## Defense: Building Secure Business Logic

OWASP's A04:2021 guidance and PortSwigger's logic-flaws lab framework converge on five engineering practices.

### 1. Document the Business Rules Explicitly

Before writing code, write down the rules in plain language and link them to specific code paths.

| Rule | Code Location | Validation Type |
|------|---------------|-----------------|
| User can redeem at most 1 coupon per day | `/api/coupons/redeem` | DB count within 24h window |
| Quantity must be a positive integer | `cart.addItem()` | Server-side type + range check |
| Transfer requires sufficient balance at commit time | `accounts.transfer()` | Row lock + `SELECT FOR UPDATE` |
| Order cannot skip `paid` state | `/api/order/{id}/status` | State machine validation |
| Role cannot be set via request payload | `users.updateProfile()` | Server-side role whitelist |

These rules must live in code review checklists, not just in design docs.

> 业务规则必须从文档下沉到代码——在代码评审清单里逐项检查。

### 2. Enforce on the Server, Always

Every business rule must have **at least one server-side enforcement**. Front-end validation is for UX, not security.

```python
# Flask example — redeem endpoint
@app.route("/api/coupons/redeem", methods=["POST"])
@rate_limit("10 per minute")  # 1. Rate limit
@login_required
def redeem():
    code = request.json.get("code")
    user = current_user

    # 2. Server-side validation
    coupon = Coupon.query.filter_by(code=code, active=True).first()
    if not coupon:
        return {"error": "invalid"}, 404

    # 3. Business rule: at most 1 redemption per user per campaign
    already_used = Redemption.query.filter_by(
        user_id=user.id, coupon_id=coupon.id
    ).first()
    if already_used:
        return {"error": "already_redeemed"}, 409

    # 4. Atomic: prevent parallel double-spend
    try:
        with db.session.begin():
            redemption = Redemption(user_id=user.id, coupon_id=coupon.id)
            db.session.add(redemption)
            user.balance += coupon.value
    except IntegrityError:
        return {"error": "conflict"}, 409

    return {"balance": user.balance}, 200
```

> 这段 Flask 代码用 4 道防护把"恶意调用、重复使用、并发双花"全部堵掉——任何一道缺失都会成为漏洞。

### 3. Use Atomic Operations for Money and Inventory

Any state change affecting **money** （货币）, **inventory** （库存）, **coupons** （优惠券）, **loyalty points** （积分）, or **referral credits** （推荐奖励） must be **atomic**:

| Pattern | Risk | Fix |
|---------|------|-----|
| `SELECT balance ... UPDATE balance -= X` (no transaction) | Race condition / double-spend | Wrap in `BEGIN ... COMMIT` with row lock |
| `if (quantity > 0) inventory -= 1` | Check-then-act race | `UPDATE inventory SET qty = qty - 1 WHERE qty > 0` (one statement) |
| `if (coupon.redeemed) ... else apply()` | Parallel redemption | Add `UNIQUE` constraint on `(user_id, coupon_id)` |
| `if (rate_limit_count < 5) count++` | Parallel bypass | Use Redis `INCR` with TTL, atomic |

> 金钱和库存操作必须是单条原子语句——任何"先查后改"都可能被并发击穿。

### 4. Model Workflows as State Machines

Instead of allowing arbitrary status updates, validate every transition:

```python
ALLOWED_TRANSITIONS = {
    "draft":     {"submitted"},
    "submitted": {"approved", "rejected"},
    "approved":  {"paid"},
    "paid":      {"delivered", "refunded"},
    "delivered": {"refunded"},
    "rejected":  set(),
    "refunded":  set(),
}

@app.route("/api/order/<id>/status", methods=["POST"])
def update_status(id):
    order = Order.query.get_or_404(id)
    new_status = request.json.get("status")
    if new_status not in ALLOWED_TRANSITIONS.get(order.status, set()):
        return {"error": "invalid_transition"}, 422
    order.status = new_status
    db.session.commit()
    return {"status": order.status}, 200
```

> 状态机校验是工作流漏洞的根治方案——把"能不能跳到这一步"用代码固化。

### 5. Pen-Test Logic, Not Just Code

Traditional pen-tests focus on injection, XSS, and access control. Logic-specific test cases include:

- Can I redeem the same coupon 100 times in parallel?
- Can I add `-1` to my cart and checkout?
- Can I update `status=delivered` without going through `paid`?
- Can I change `price` in the request body and get a discount?
- Can I submit 1,000 password-reset requests per second per user?

These are **scenario-based tests** （场景化测试） rather than payload-based tests. A senior red-team consultant once said: *"If you can describe the exploit in plain English without ever mentioning payload syntax, you have probably found a logic flaw."*

> 业务逻辑测试靠场景想象而非 payload 构造——能用白话描述的漏洞，往往就是逻辑漏洞。

---

## Detection in Production

Even well-designed applications get logic flaws. **Detection engineering** （检测工程） focuses on behavioural anomalies:

| Signal | Tool / Source | What to Alert On |
|--------|---------------|------------------|
| Same coupon redeemed N times in 1 second | WAF / API gateway logs | Single user_id, parallel requests |
| Negative cart total | SIEM custom rule | E-commerce checkout API |
| `status=delivered` without prior `paid` | Application audit log | Order state transition trail |
| Balance going negative | Database trigger + alert | Real-time balance monitoring |
| Repeated `POST /reset_password` from one IP | API gateway + rate limit logs | Possible enumeration |

Critical practice: enable **audit logging** （审计日志） on every state transition in money-bearing workflows. The log line `order_id=12345 prev_state=paid next_state=refunded user=admin timestamp=...` is the only forensic evidence after a logic-flaw exploit.

> 状态机审计日志是业务逻辑漏洞事后溯源的唯一抓手——必须开启。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Business Logic Vulnerability | 业务逻辑漏洞 | 业务流程设计缺陷导致可被利用的错误 |
| Logic Flaw | 逻辑缺陷 | "Logic flaw" 与 business logic vulnerability 同义 |
| Business Rule Bypass | 业务规则绕过 | 攻击者规避业务限制达成未授权行为 |
| Insecure Design | 不安全设计 | OWASP A04:2021，设计阶段缺失的安全控制 |
| CWE-840 | CWE-840 业务逻辑错误 | 公共缺陷枚举中对业务逻辑漏洞的编号 |
| Rate Limit | 速率限制 | 限制单位时间内请求次数的防护机制 |
| Coupon Stacking | 优惠券叠加 | 多次使用本应单次使用的优惠 |
| Race Condition | 竞态条件 | 并发执行导致结果依赖执行顺序的缺陷 |
| TOCTOU | 检查时间/使用时间差漏洞 | Time-Of-Check to Time-Of-Use 首字母缩写 |
| Atomic Operation | 原子操作 | 不可分割的数据库事务或系统调用 |
| State Machine | 状态机 | 把业务流转建模为有限状态集合 |
| Workflow Bypass | 流程绕过 | 跳过业务流程中应必经的步骤 |
| Workflow State Violation | 流程状态违例 | 不按允许的转换路径变更业务状态 |
| Account Takeover | 账户接管 | 攻击者获得合法用户账户的控制权 |
| Negative Quantity | 负数量 | 利用数量字段取负值导致总价为负 |
| Client-Side Validation | 客户端校验 | 仅在浏览器侧执行的输入校验，易被绕过 |
| Server-Side Validation | 服务端校验 | 在服务器执行的权威校验，是安全决策的唯一来源 |
| Audit Log | 审计日志 | 记录状态变更、权限操作等关键事件的日志 |
| Atomicity | 原子性 | 事务要么全部成功、要么全部回滚的特性 |

---

## 甲方视角思考

1. **登录限流不等于全站限流** — 优惠券核销、礼品卡验证、密码重置确认、API 调用都要单独设计速率限制，登录框的限流策略不能简单套用。
2. **任何"先查后改"的钱/库存操作都是高危目标** — 从转账到扣库存到发券，凡是分两步的代码路径都是并发攻击面，审计时优先搜索"SELECT ... 后 UPDATE"模式。
3. **状态机是流程类漏洞的根治方案** — 订单、审批、KYC、风控等工作流必须用代码层面的状态转换白名单固化，"当前状态 + 下一状态"在数据库层校验。
4. **审计日志的覆盖率就是 SOC 的取证能力上限** — 涉及金额、状态、权限变更的接口必须输出结构化审计日志（用户、对象、前后值、时间戳），否则逻辑漏洞事后无法溯源。

---

## Tomorrow — Day 27 Preview

**HTTP Request Smuggling** — we will return to a network-level technical topic: how **CL.TE** and **TE.CL** desync attacks exploit discrepancies between front-end proxies and back-end servers in `Content-Length` / `Transfer-Encoding` parsing. We will cover the smuggling primitives, bypass of front-end security controls, and the strict **RFC 7230** parsing rules that prevent them. Difficulty remains ★★★☆☆.
