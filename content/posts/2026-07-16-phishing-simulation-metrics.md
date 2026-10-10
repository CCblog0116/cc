---
title: "Day 9 — Phishing Simulation Metrics"
date: 2026-07-16
tags:
  - daily
  - security
  - english
description: "The Wrong Question Most CISOs Ask（大多数 CISO 问错了问题）"
---

**日期：2026-07-16**
**难度：★★☆☆☆ 概念进阶（Concepts）**
**来源：SANS Security Awareness Blog — "Why a Phishing Click Rate of 0% is Bad" by Lance Spitzner + SANS Security Awareness Maturity Model**
**原文链接：https://www.sans.org/latest/security-awareness-training/blog/why-phishing-click-rate-0-bad/**

---

## 📖 文章正文

### The Wrong Question Most CISOs Ask（大多数 CISO 问错了问题）

When organizations launch their first **phishing simulation** (钓鱼演练), one question almost always comes up: *"What should our click rate (点击率) be?"* Many teams aim for 0%, treating every click as a personal failure. According to **Lance Spitzner** (兰斯·斯皮茨纳), Senior Instructor at the SANS Institute, this is exactly the wrong mindset — and a potentially dangerous one.

> 0% 点击率不是目标，反而是"安全错觉"的信号。钓鱼演练是 control（控制措施），不是 pass/fail 的考试。

---

### The Real Benchmark: Drop Over Time（真正的基准：随时间下降）

Spitzner, who has worked with hundreds of organizations worldwide, shares a simple rule of thumb: an **under 5% click rate** (点击率低于 5%) is a reasonable starting goal, but the more important number is the **trend** (趋势), not the absolute value. His typical observations:

| Stage | Click Rate | Notes |
|-------|-----------|-------|
| **First simulation** (首次演练) | 25 – 30% | Baseline; completely normal |
| **After 9 – 18 months** (持续 9-18 个月) | < 5% | Mature awareness program |
| **Highly mature program** (高度成熟) | 1 – 2% | The remaining 2% are usually new hires |

These numbers apply to **Tier 01 phishing** (一级钓鱼) — generic, opportunistic emails with no personal context. The moment you move into **spear phishing** (鱼叉式钓鱼) or **BEC** (商业邮件欺诈), where the email is personalized using **OSINT** (公开来源情报) scraped from LinkedIn or company websites, click rates climb again.

> 第一次演练 25-30% 点击率是正常的，不是培训失败。甲方别被这个数字吓到去处罚员工。

---

### Why 0% Is a Bad Goal（为什么 0% 是坏目标）

This is the core of Spitzner's argument, and the most counter-intuitive insight for security leaders:

1. **People will always click.** No matter how much you train, someone will eventually click on a well-crafted email. Mistakes are part of being human. Treating awareness as a control that *eliminates* risk is the same mistake as believing antivirus *eliminates* malware.
2. **A click is a teachable moment** (教学时刻). When an employee clicks a simulated link and sees the warning page, it becomes an **emotional event** (情绪化体验) — one they will rarely forget. They are far more likely to never fall for that trick again. This emotional anchor is something no annual 45-minute training video can replicate.
3. **You WANT people to click on simulations.** If 0% of your workforce clicks, it almost certainly means one of three things: your simulations are too easy, people have figured out how to game the test (forwarding the suspicious email to each other), or new hires are being warned in advance. All three destroy the training value.
4. **The 2% who click are usually new hires** (新员工). Falling for a phishing simulation is, as Spitzner puts it, "a right of passage" for new employees. Punishing them is punishing them for learning.

> 教学时刻 > 完美数据。让员工在"安全的演练"中被骗一次，比在真实事件中泄露账号便宜得多。

---

### The Metric You Should Actually Watch（你真正该盯的指标：重复点击者）

Spitzner is blunt: a single click is **noise** (噪声). What matters is the **repeat clicker** (重复点击者) — the small group of employees who click on every simulation, month after month, despite repeated training. They are your **human risk indicators** (人类风险指标) and deserve targeted, respectful coaching.

In other words, mature programs stop asking *"what was our click rate?"* and start asking *"how many of our clickers from last quarter clicked again this quarter?"*

> 真正的高风险信号是"持续点"和"反复点"，而不是"单次点"。甲方应该把培训资源集中在那一小撮重复点击者身上。

---

### Beyond Click Rate: A Modern Metric Set（超越点击率：现代指标体系）

The industry is moving past click rate as the headline KPI. A well-designed program tracks multiple metrics that together describe a **resilient workforce** (有韧性的员工团队):

- **Click rate** (点击率): % who clicked the simulated link. Easy to game; useful only as a trend.
- **Submission rate** (提交率): % who entered credentials on the landing page. Often 40 – 60% of clickers, and far more dangerous.
- **Report rate** (报告率): % who reported the email as suspicious. The clearest signal of an engaged security culture.
- **Mean Time to Report (MTTR)** (平均报告时间): How fast the first employee flagged the email. A short MTTR dramatically narrows the window of exposure to a real attack.
- **Repeat offender rate** (重复点击者比例): The percentage of clickers who failed again in the next campaign. The single most diagnostic metric for program health.

According to the 2025 Gartner Security & Risk Management report, organizations with a report rate above 60% show an 80% lower risk of phishing compromise than the rest.

> 报告率比点击率更能反映真实安全文化。甲方要奖励"报上来"的行为，而不是惩罚"点错"的行为。

---

### The SANS Security Awareness Maturity Model（SANS 安全意识成熟度模型）

Spitzner's broader framework, the **SANS Security Awareness Maturity Model** (SANS 安全意识成熟度模型), describes five stages organizations go through:

| Level | Stage | Characteristics |
|-------|-------|-----------------|
| **1** | **Nonexistent** (不存在) | No program at all; awareness happens by accident. |
| **2** | **Compliance-Focused** (合规驱动) | Annual training to satisfy regulations; checkbox culture. |
| **3** | **Promoting Awareness & Behavior Change** (行为改变) | Regular training, simulations, metrics, and leadership engagement. |
| **4** | **Long-Term Sustainment & Culture Change** (文化塑造) | Security is embedded in the organization's identity; employees report proactively. |
| **5** | **Metrics Framework** (指标驱动) | Continuous measurement, behavior-based KPIs, and risk-based ROI calculations. |

Most organizations today sit between Level 2 and Level 3. The journey from 3 to 4 is not about better phishing templates — it is about **psychological safety** (心理安全感): employees must trust that reporting a mistake will not get them in trouble.

> 钓鱼演练不只是技术问题，更是组织文化问题。员工敢不敢报告，往往比他们会不会点击更重要。

---

### Common Pitfalls: What Goes Wrong in Real Programs（常见陷阱：真实项目哪里翻车）

1. **Gotcha culture** (抓人文化): Naming and shaming repeat clickers in front of colleagues. Result: the report rate collapses because employees hide mistakes.
2. **Generic templates** (通用模板): Using obvious "Nigerian prince" style emails that nobody would click. Result: false confidence, no real learning.
3. **One-shot annual tests** (一年一次): A single simulation per year measures nothing and changes nothing. **Cognitive science** (认知科学) shows people forget ~80% of new information within 30 days without reinforcement.
4. **Punishing first-time clickers** (处罚首次点击者): As Spitzner warns, this turns a teaching moment into a fear event. Use it as onboarding, not discipline.
5. **Ignoring the reporting channel** (忽略报告渠道): If employees have no easy button to report suspicious emails, your entire program loses its early-warning value.

> 甲方最常犯的错是把钓鱼演练做成"年度抓人 KPI"。真正成熟的项目是月度、连续、随难度递进，并且永远把"报告"放在比"点击"更高的位置。

---

## 🧠 今日关键词速查表

| English | 中文 | 备注 |
|---------|------|------|
| Phishing Simulation | 钓鱼演练 / 模拟钓鱼 | 用安全可控的假邮件测试员工反应 |
| Click Rate | 点击率 | 模拟邮件中点击链接的员工比例 |
| Submission Rate | 提交率 | 点击后还在伪造页面上输入凭证的比例 |
| Report Rate | 报告率 | 把可疑邮件主动上报给安全团队的比例 |
| Mean Time to Report (MTTR) | 平均报告时间 | 从邮件发送到首个员工上报的时间间隔 |
| Repeat Offender | 重复点击者 | 多次演练都点错的高风险员工 |
| Teachable Moment | 教学时刻 | 员工犯错的瞬间进行即时教育，效果最佳 |
| Spear Phishing | 鱼叉式钓鱼 | 用个人信息定制的精准钓鱼 |
| BEC | 商业邮件欺诈 | Business Email Compromise，冒充高管/合作伙伴 |
| OSINT | 公开来源情报 | Open-Source Intelligence，从公开渠道收集目标信息 |
| Tier 01 Phishing | 一级钓鱼 | 通用、无针对性的钓鱼邮件 |
| Phishing-Resistant MFA | 防钓鱼 MFA | FIDO2/WebAuthn 这类可对抗实时钓鱼的认证方式 |
| Security Awareness Maturity Model | 安全意识成熟度模型 | SANS 提出的 5 级组织安全文化评估框架 |
| Psychological Safety | 心理安全感 | 员工相信上报错误不会被惩罚的组织氛围 |
| Compliance-Focused | 合规驱动 | 仅满足监管要求、缺乏行为改变的安全意识项目 |
| Reinforcement | 反复强化 | 间隔重复教学以对抗遗忘曲线 |
| Cognitive Science | 认知科学 | 研究人如何记忆、注意和学习的学科 |
| False Sense of Security | 虚假安全感 | 因为某项指标好看而误以为风险已消除 |

---

## 🛡️ 甲方视角思考

- **0% 点击率不是 KPI**：把 25-30% 当成"首测基线"，把"季度环比下降"当成真正目标。SANS 数据显示，成熟项目稳定在 1-2%，剩下的 2% 大多是新员工——这是学习成本，不是失败。
- **报告率比点击率重要 10 倍**：高点击率 + 高报告率 = 健康；低点击率 + 低报告率 = 沉默的灾难。要给员工一个"一键上报"按钮，并奖励上报行为。
- **千万别把演练做成"抓人游戏"**：公开羞辱或处罚点击者 = 报告率直接腰斩。Gartner 数据显示，用钓鱼演练结果做纪律处分会让报告率下降 75%。MFA 保护凭证，但只有人会主动报告。
- **月度演练 + 难度递增 + 不同部门场景**：财务发 BEC、HR 发简历诈骗、IT 发密码重置；季度轮换模板；3-6 个月能明显看到文化质变。

---

## 🎯 明日预告

Day 10 将继续 **★★☆☆☆ 概念级** 学习，主题为：**Identity & Access Management (IAM) Fundamentals（身份与访问管理基础）**——AAA（Authentication / Authorization / Accounting）三大支柱、RBAC vs ABAC 模型选择、特权账号管理（PAM）、以及为什么 IAM 是零信任架构的"第一块拼图"。
