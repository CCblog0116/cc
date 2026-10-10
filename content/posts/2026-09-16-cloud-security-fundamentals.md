---
title: "Day 31 — Cloud Security Fundamentals: Shared Responsibility, IAM, and Storage Risks"
date: 2026-09-16
tags:
  - daily
  - security
  - english
description: "⭐ Difficulty: ★★★☆☆ Technical"
---

📅 **Date:** September 16, 2026  
⭐ **Difficulty:** ★★★☆☆ Technical  
📰 **Source:** AWS Security Documentation + CSA (Cloud Security Alliance) + NIST SP 800-144  
🔗 **Reference:** [https://docs.aws.amazon.com/security/](https://docs.aws.amazon.com/security/)

---

## 1. Why Cloud Security Is Different

Moving workloads to the cloud does not eliminate security responsibility — it shifts it. In a traditional data center, the organization owns the entire stack from the physical rack to the application layer. In the cloud, the provider manages some layers while the customer manages others. Misunderstanding this boundary is one of the most common causes of cloud breaches.

For security teams, the cloud introduces new attack surfaces: **metadata services**（元数据服务） that expose credentials, **object storage**（对象存储） buckets left open to the internet, overly permissive **IAM policies**（IAM 策略）, and invisible **shadow IT**（影子 IT） resources spun up by developers without approval. 对甲方而言，云资产的可变性和自助开通特性让传统资产盘点方式失效，需要依赖 CSPM（云安全态势管理）工具持续发现。

---

## 2. The Shared Responsibility Model

The **Shared Responsibility Model**（责任共担模型） defines who is responsible for what in a cloud deployment. The exact split depends on the service model:

| Service Model | Provider Manages | Customer Manages |
|---------------|------------------|------------------|
| **IaaS**（基础设施即服务） | Physical infrastructure, hypervisor, network fabric | OS, applications, data, IAM, encryption, network config |
| **PaaS**（平台即服务） | Runtime, middleware, OS patching | Application code, data, IAM, API security |
| **SaaS**（软件即服务） | Almost everything | User accounts, data classification, endpoint security |

A common mistake is assuming the cloud provider secures everything. If you deploy a virtual machine on **IaaS**（基础设施即服务） and never patch the operating system, that vulnerability is your responsibility, not the provider's.

> 简短中文提醒：使用 IaaS 时，操作系统补丁、应用加固、数据加密和访问控制全部由租户负责，不能把安全责任"甩锅"给云厂商。

---

## 3. Identity and Access Management (IAM)

**IAM**（身份与访问管理） is the control plane of cloud security. If an attacker compromises IAM credentials, they can control your entire cloud environment. Good IAM hygiene is therefore non-negotiable.

### Core Principles

- **Least privilege**（最小权限）: Grant only the permissions required for a specific task. Avoid wildcard permissions such as `*` on `*`.
- **Role-based access**（基于角色的访问）: Use roles instead of long-lived access keys wherever possible. Roles are temporary and scoped.
- **Multi-factor authentication (MFA)**（多因素认证）: Enforce MFA for all privileged users and root accounts.
- **No hardcoded credentials**（禁止硬编码凭据）: Never embed access keys in source code, configuration files, or environment variables checked into version control.

### Dangerous Patterns to Avoid

```json
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}
```

This policy grants full administrative access. It is the cloud equivalent of giving everyone the root password. Attackers who find such a credential can exfiltrate data, launch resources, or destroy infrastructure.

---

## 4. Cloud Metadata Service Risks

Cloud instances can query a **metadata service**（元数据服务） to obtain information about themselves, including temporary credentials. On AWS, this is available at `http://169.254.169.254/latest/meta-data/`. The original **IMDSv1**（实例元数据服务版本 1） did not require authentication, making it vulnerable to **Server-Side Request Forgery (SSRF)**（服务器端请求伪造） attacks.

An attacker who finds an SSRF vulnerability in your application can ask the metadata service for the instance's temporary IAM credentials. Those credentials may have broad permissions, turning a minor SSRF into a full cloud compromise.

**IMDSv2**（实例元数据服务版本 2） mitigates this by requiring a session-oriented request: the client must first obtain a token via a `PUT` request, then use that token for subsequent queries. You should enforce IMDSv2 and disable IMDSv1 on all instances.

> 简短中文提醒：SSRF + IMDSv1 是云环境典型的"小洞打大仗"组合，甲方应通过基线扫描强制所有云主机启用 IMDSv2。

---

## 5. Object Storage Security

**Object storage**（对象存储） services such as AWS S3, Azure Blob Storage, and Alibaba Cloud OSS are deceptively simple. A single misconfiguration can expose terabytes of sensitive data to the public internet.

Common misconfigurations include:

- **Public read access**（公共读取权限） on buckets or individual objects
- **Overly permissive bucket policies**（过度宽松的存储桶策略） that grant access to anonymous users
- **Disabled logging and versioning**（未启用日志和版本控制）, making it impossible to audit access or recover from ransomware
- **Sensitive data without encryption**（未加密的敏感数据） at rest or in transit

Defense checklist:

| Control | Action |
|---------|--------|
| Block public access | Enable the provider's "block all public access" setting at the account level |
| Encryption at rest | Enable server-side encryption with a customer-managed key |
| Encryption in transit | Enforce HTTPS-only access |
| Logging | Enable access logging and ship logs to a SIEM |
| Versioning | Enable object versioning to protect against deletion or overwrite |
| Lifecycle policies | Define retention and automated deletion rules |
| IAM policies | Restrict access to specific roles and VPC endpoints |

---

## 6. Network Segmentation in the Cloud

Traditional network segmentation relies on physical firewalls and VLANs. In the cloud, segmentation is software-defined. **Virtual Private Clouds (VPCs)**（虚拟私有云）, **subnets**（子网）, **security groups**（安全组）, and **network ACLs**（网络访问控制列表） replace the hardware perimeter.

Best practices:

- Place critical workloads in **private subnets**（私有子网） with no direct internet access
- Use **bastion hosts**（堡垒机） or **jump servers**（跳板机） for administrative access
- Apply **security groups**（安全组） as stateful host-level firewalls — allow only necessary ports and sources
- Enable **VPC flow logs**（VPC 流量日志） for traffic analysis and anomaly detection
- Use **cloud-native firewalls**（云原生防火墙） or **WAFs**（Web 应用防火墙） at the edge for application-layer protection

---

## 7. Cloud Security Posture Management (CSPM)

**CSPM**（云安全态势管理） tools continuously scan cloud environments for misconfigurations, policy violations, and compliance gaps. They answer questions such as: Is there an exposed storage bucket? Is a security group open to `0.0.0.0/0`? Is encryption disabled anywhere?

For security teams, CSPM is the cloud equivalent of vulnerability scanning. Integrate it with your **SIEM**（安全信息与事件管理） or **SOAR**（安全编排自动化与响应） platform so that findings trigger automated remediation tickets or alerts.

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Shared Responsibility Model | 责任共担模型 | Defines provider vs. customer security duties |
| IaaS / PaaS / SaaS | 基础设施/平台/软件即服务 | Three cloud service models with different responsibility splits |
| IAM (Identity and Access Management) | 身份与访问管理 | Cloud control plane for authentication and authorization |
| Least privilege | 最小权限 | Grant only necessary permissions |
| Metadata service | 元数据服务 | Internal endpoint exposing instance data and credentials |
| IMDSv1 / IMDSv2 | 实例元数据服务版本 1/2 | AWS metadata endpoints; v2 requires session tokens |
| Object storage | 对象存储 | Scalable storage for files (S3, Blob, OSS) |
| Bucket policy | 存储桶策略 | JSON-based access rules for object storage |
| VPC (Virtual Private Cloud) | 虚拟私有云 | Isolated cloud network segment |
| Security group | 安全组 | Stateful virtual firewall at the instance level |
| Network ACL | 网络访问控制列表 | Stateless subnet-level firewall |
| Private subnet | 私有子网 | Subnet with no direct internet route |
| Bastion host / Jump server | 堡垒机 / 跳板机 | Hardened intermediary for admin access |
| VPC flow logs | VPC 流量日志 | Records of IP traffic within the VPC |
| CSPM | 云安全态势管理 | Automated cloud configuration and compliance scanning |
| Shadow IT | 影子 IT | Unauthorized cloud resources deployed by employees |
| Encryption at rest | 静态加密 | Data encryption when stored on disk |
| Encryption in transit | 传输加密 | Data encryption over the network (TLS/HTTPS) |

---

## 甲方视角思考

- **云资产全量纳管**：通过云厂商 API 自动同步所有账号、VPC、存储桶、云主机清单，避免影子资产游离于监管之外。  
- **IAM 权限最小化审计**：每季度 review 一次 IAM policy，清理 wildcard 权限、长期 AccessKey 和未使用的 ServiceAccount。  
- **基线扫描自动化**：在 CI/CD 或定时任务中集成 CSPM / Terraform 安全扫描，阻断公开存储桶和 IMDSv1 配置上线。  
- **云网流量可视化**：将 VPC flow logs 和云防火墙日志接入 SIP / 流量探针，补齐云上东西向流量的检测盲区。  

---

## Tomorrow's Preview — Day 32

**Topic:** Container and Kubernetes Security  
**What to expect:** We'll dive into **container**（容器） fundamentals — image vulnerabilities, **Dockerfile**（Docker 文件） hardening, and the **Kubernetes**（Kubernetes） attack surface. You'll learn about **pod security standards**（Pod 安全标准）, **RBAC**（基于角色的访问控制） in K8s, **network policies**（网络策略）, and **supply-chain risks**（供应链风险） in container registries. As cloud-native adoption grows, this is essential knowledge for any defender.
