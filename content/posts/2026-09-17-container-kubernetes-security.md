---
title: "Day 32 — Container and Kubernetes Security: Images, Pods, and Cluster Hardening"
date: 2026-09-17
tags:
  - daily
  - security
  - english
description: "⭐ Difficulty: ★★★☆☆ Technical"
---

📅 **Date:** September 17, 2026  
⭐ **Difficulty:** ★★★☆☆ Technical  
📰 **Source:** Kubernetes Security Documentation + CNCF + NIST SP 800-190  
🔗 **Reference:** [https://kubernetes.io/docs/concepts/security/](https://kubernetes.io/docs/concepts/security/)

---

## 1. Why Container Security Matters

**Containers**（容器） package an application with all its dependencies into a single, portable unit. They make deployment fast and consistent, but they also introduce a new attack surface. A vulnerable container image can be deployed thousands of times across a cluster, amplifying a single flaw into a widespread compromise.

For security teams, the shift from virtual machines to containers changes how we think about isolation. Containers share the host **kernel**（内核）, so escaping a container often means gaining access to the host and every other container on it. 对甲方而言，容器化让资产边界变得模糊，传统的“一台主机一个资产”盘点方式需要升级为镜像、仓库、命名空间的多维视角。

---

## 2. Container Image Risks

A **container image**（容器镜像） is built from layers, each defined by instructions in a **Dockerfile**（Docker 文件）. Security issues can hide in any layer: the base operating system, installed packages, copied source code, or even build tools left behind.

Common image risks include:

- **Known vulnerabilities**（已知漏洞） in base images or dependencies — often disclosed as CVEs
- **Hardcoded secrets**（硬编码密钥） embedded in image layers, such as API keys or passwords
- **Unnecessary privileges**（不必要权限） like running as the `root` user inside the container
- **Large attack surface**（过大攻击面） from debug tools, compilers, or shells included in production images

Defense starts with choosing minimal base images such as **Distroless**（无发行版镜像） or **Alpine**（Alpine Linux 精简镜像）, scanning every image before deployment, and removing build-time secrets with multi-stage builds. 简短中文提醒：镜像分层意味着删除敏感文件并不能真正清除历史，构建阶段写入的密钥仍可通过 `docker history` 或解压镜像层被恢复。

---

## 3. Dockerfile Hardening Checklist

A hardened Dockerfile follows the principle of least privilege at build time and runtime:

| Practice | Why It Helps |
|----------|--------------|
| Use official or minimal base images | Reduces the number of packages that may contain CVEs |
| Pin image tags to specific digests | Prevents **supply-chain attacks**（供应链攻击） from tag mutation |
| Run as a non-root user | Limits the impact of container escape or application compromise |
| Use multi-stage builds | Keeps build tools and secrets out of the final image |
| Remove package managers and shells | Shrinks the attack surface available to an intruder |
| Scan images in CI/CD | Catches vulnerabilities before they reach production |

Here is a concise example of a hardened Dockerfile pattern:

```dockerfile
# Build stage
FROM golang:1.23 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o server

# Runtime stage
FROM gcr.io/distroless/static-debian12
WORKDIR /app
COPY --from=builder /app/server .
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["./server"]
```

This pattern separates compilation from runtime and leaves no shell or package manager in the final image.

---

## 4. Kubernetes Attack Surface

**Kubernetes**（Kubernetes，简称 K8s） orchestrates containers at scale. Its control plane includes several components that are attractive targets:

- **API server**（API 服务器）: The central management endpoint; anyone with access can control the cluster
- **etcd**（etcd 分布式键值存储）: Stores all cluster state, including secrets in plaintext by default
- **Kubelet**（Kubelet 节点代理）: Runs on every worker node and manages containers
- **Scheduler**（调度器） and **controller manager**（控制器管理器）: Influence where and how workloads run

If an attacker gains access to the API server, they can create privileged pods, extract secrets, or pivot to underlying nodes. Therefore, protecting the API server is the top priority in cluster hardening.

---

## 5. RBAC and Least Privilege in Kubernetes

**Role-Based Access Control (RBAC)**（基于角色的访问控制） in Kubernetes defines who can perform which actions on which resources. Default permissions should be denied; roles should grant only what is necessary.

Key RBAC objects include:

- **Role**（角色）: Permissions within a single namespace
- **ClusterRole**（集群角色）: Permissions across the entire cluster
- **RoleBinding**（角色绑定） / **ClusterRoleBinding**（集群角色绑定）: Attach roles to users, groups, or service accounts

Dangerous patterns mirror cloud IAM mistakes. A `ClusterRole` with `*` on `*` resources and verbs is equivalent to cluster admin access. Service accounts with excessive permissions are a common pivot point for attackers who compromise an application pod.

> 简短中文提醒：甲方应定期审计 `cluster-admin` 绑定和具备 `create pods` 权限的 ServiceAccount，这些往往是横向移动的“高速公路”。

---

## 6. Pod Security Standards

**Pod Security Standards**（Pod 安全标准） define three policy levels for pod hardening:

| Level | Description | Typical Restriction |
|-------|-------------|---------------------|
| **Privileged**（特权级） | Unrestricted, highest risk | Allowed in trusted admin namespaces only |
| **Baseline**（基线级） | Prevents known high-risk configurations | Blocks host namespaces, hostPath volumes, privileged mode |
| **Restricted**（受限级） | Defense-in-depth defaults | Requires non-root, read-only root FS, drops all capabilities |

Enforce these standards using the built-in **Pod Security Admission**（Pod 安全准入） controller or alternatives such as **OPA Gatekeeper**（Open Policy Agent 网守） and **Kyverno**（Kyverno 策略引擎）. Restricted should be the default for application workloads.

---

## 7. Network Policies and Segmentation

By default, every pod in a Kubernetes cluster can talk to every other pod. This flat network is convenient but dangerous. **Network Policies**（网络策略） act as cluster-internal firewalls, allowing only explicitly permitted traffic between namespaces or pod groups.

Best practices:

- **Default-deny**（默认拒绝） egress and ingress policies for sensitive namespaces
- Allow traffic only from specific namespaces or labels
- Segment control-plane traffic from workload traffic
- Combine with service mesh for mutual TLS and fine-grained authorization

Network segmentation inside a cluster reduces the blast radius if one application is compromised.

---

## 8. Registry and Supply-Chain Risks

The container **registry**（镜像仓库） is part of the software supply chain. If an attacker can push a malicious image, they can compromise every environment that pulls from that registry.

Defense measures include:

- **Image signing**（镜像签名） with tools such as **Sigstore / Cosign**（Sigstore/Cosign 镜像签名工具）
- **Admission controllers**（准入控制器） that verify signatures before deployment
- **Private registries**（私有镜像仓库） with strong authentication
- **Vulnerability scanning**（漏洞扫描） integrated into CI/CD and runtime
- **Software Bill of Materials (SBOM)**（软件物料清单） generation for every image

> 简短中文提醒：镜像签名比单纯的“可信仓库”更可靠，因为即使仓库账号被盗，没有私钥也无法伪造合法签名。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Container | 容器 | Lightweight, portable application runtime unit |
| Container image | 容器镜像 | Read-only template used to create containers |
| Dockerfile | Docker 文件 | Script defining how a container image is built |
| Kernel | 内核 | Core operating-system component shared by containers on a host |
| Container escape | 容器逃逸 | Breaking out of a container to access the host |
| Distroless | 无发行版镜像 | Minimal image without package manager or shell |
| Alpine | Alpine Linux 精简镜像 | Small Linux distribution often used as a base image |
| CVE | 通用漏洞披露 | Publicly disclosed cybersecurity vulnerability identifier |
| Multi-stage build | 多阶段构建 | Dockerfile technique to separate build and runtime artifacts |
| Kubernetes (K8s) | Kubernetes | Container orchestration platform |
| API server | API 服务器 | Central Kubernetes control-plane component |
| etcd | etcd 分布式键值存储 | Stores all cluster state and secrets |
| Kubelet | Kubelet 节点代理 | Agent that runs containers on each node |
| RBAC | 基于角色的访问控制 | Role-Based Access Control for cluster permissions |
| Role / ClusterRole | 角色 / 集群角色 | Permission definitions scoped to namespace or cluster |
| Pod Security Standards | Pod 安全标准 | Three policy levels for pod hardening |
| Privileged mode | 特权模式 | Grants a pod extended host-level capabilities |
| Network Policy | 网络策略 | Kubernetes firewall rules for pod-to-pod traffic |
| Default-deny | 默认拒绝 | Block all traffic unless explicitly allowed |
| Registry | 镜像仓库 | Storage and distribution service for container images |
| Image signing | 镜像签名 | Cryptographic verification of image authenticity |
| Sigstore / Cosign | Sigstore/Cosign 镜像签名工具 | Open-source project for signing and verifying container images |
| Admission controller | 准入控制器 | Intercepts requests to enforce policies before persistence |
| SBOM | 软件物料清单 | Inventory of components in a software artifact |
| Supply-chain attack | 供应链攻击 | Compromise introduced through trusted distribution channels |

---

## 甲方视角思考

- **镜像安全左移**：在 CI/CD 中集成镜像扫描和 SBOM 生成，阻断含高危 CVE 或未签名镜像进入生产仓库。  
- **K8s RBAC 最小化**：按命名空间梳理 RoleBinding，清理 cluster-admin 滥用和具备 pod/exec 权限的 ServiceAccount。  
- **集群网络微分段**：对核心 namespace 启用 default-deny NetworkPolicy，结合服务网格实现东西向流量鉴权。  
- **运行时威胁检测**：在节点部署轻量 Agent，监控容器逃逸、敏感目录挂载和异常进程行为，并接入 SIP / 态势感知平台。

---

## Tomorrow's Preview — Day 33

**Topic:** CI/CD and DevSecOps Pipeline Security  
**What to expect:** We'll explore how security integrates into the software delivery pipeline. You'll learn about **version control**（版本控制） risks, **secrets management**（密钥管理） in pipelines, **SAST / DAST**（静态 / 动态应用安全测试）, **dependency scanning**（依赖扫描）, **infrastructure as code**（基础设施即代码） security, and protecting build agents from compromise. As automation accelerates releases, securing the pipeline itself becomes just as important as securing production.
