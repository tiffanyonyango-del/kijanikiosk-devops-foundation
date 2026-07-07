# Hardening Decisions for the KijaniKiosk Infrastructure

## Introduction
This document explains the security decisions that were implemented while building the KijaniKiosk infrastructure. The goal of this project was not only to provision three Linux servers automatically but also to ensure that they are configured in a secure, repeatable and maintainable way.

The infrastructure is provisioned using Terraform and configured using Ansible. Terraform provides consistent infrastructure deployment, while Ansible ensures every server reaches the same secure configuration without requiring manual administration. This combination reduces configuration drift and makes rebuilding the environment predictable.

The deployment consists of three servers:

- API
- Payments
- Logs

Each server is configured from the same automation code while still allowing server-specific values through Ansible variables.

---

## Security Controls

| Control | What it does | Risk mitigated |
|---------|---------------|----------------|
| Remote Terraform state | Stores Terraform state outside the local machine using MinIO. | Prevents accidental loss of infrastructure state and improves collaboration. |
| Variables instead of hardcoded values | Environment-specific values such as region and instance type are stored as variables. | Reduces configuration mistakes and makes deployments reusable. |
| SSH key authentication | Servers authenticate using SSH keys instead of passwords. | Reduces the risk of password attacks and credential guessing. |
| Firewall rules | Only required ports such as SSH and HTTP are permitted. | Minimizes the attack surface by blocking unnecessary network access. |
| Dedicated service accounts | Each KijaniKiosk service runs under its own Linux user. | Prevents one compromised service from affecting the others. |
| systemd sandboxing | The Payments service uses systemd hardening directives including ProtectSystem, ProtectHome, NoNewPrivileges and PrivateTmp. | Limits the damage that can occur if the service becomes compromised. |
| Persistent logging | System logs remain available after system reboots. | Preserves audit information for troubleshooting and investigations. |
| Log rotation | Application logs are rotated and compressed automatically. | Prevents excessive disk usage while preserving historical logs. |

---

## Terraform Security Decisions

Terraform was used to provision the infrastructure in a consistent and repeatable manner. The infrastructure is created from reusable modules rather than duplicated configuration blocks. This reduces maintenance effort while ensuring every server follows the same baseline configuration.

All deployment-specific information such as the instance type, deployment region and SSH key name is stored in variables rather than being embedded inside Terraform resources. This approach makes the configuration portable between environments while reducing the likelihood of accidental configuration mistakes.

The project also stores Terraform state remotely using MinIO. A remote state backend allows infrastructure information to survive local machine failures and enables future collaboration between multiple operators. Although MinIO provides compatibility with Terraform's S3 backend, it does not provide native state locking.

In a production deployment this limitation would normally be addressed by using AWS S3 together with DynamoDB for state locking, Google Cloud Storage with its built-in locking capabilities, or Consul as a vendor-independent backend. These approaches prevent multiple users from modifying infrastructure simultaneously and reduce the possibility of state corruption.

Terraform also demonstrates idempotent infrastructure management. After the initial deployment, subsequent runs produce no infrastructure changes unless the configuration itself has been modified. This predictable behaviour reduces operational risk and allows infrastructure updates to be performed safely.

---

## Ansible Security Decisions

Ansible configures all three servers from a clean Ubuntu installation to the required system state.

Instead of maintaining separate playbooks for every server, common configuration is shared through group variables while server-specific values are stored in host variables. This improves maintainability and reduces duplicated configuration.

Templates are used to generate configuration files dynamically. This ensures every server receives consistent configuration while allowing service-specific values to be substituted automatically.

Handlers restart services only when configuration changes occur. This minimizes unnecessary service interruptions and supports idempotent operation.

Running the playbook a second time results in no configuration changes being reported. This confirms that the desired state has already been achieved and demonstrates reliable automation.

---

## systemd Hardening

The Payments service was further protected using systemd security directives.

These restrictions prevent the service from modifying sensitive areas of the operating system, limit available privileges, isolate temporary storage, restrict available capabilities and reduce the number of system resources accessible to the running process.

The resulting security score for the Payments service is:

**overall exposure level: 1.0**

This is significantly below the required maximum score of 2.5 and demonstrates that the service operates inside a substantially hardened execution environment.

---

## Remaining Risks

Although the implemented controls provide a strong security baseline, they do not eliminate every possible risk.

This deployment does not currently include intrusion detection, vulnerability scanning, centralized secret management, automated certificate management or continuous security monitoring. The infrastructure also relies on SSH key protection by administrators and does not implement multi-factor authentication for server access.

In a production environment these controls would be complemented by centralized monitoring, regular patch management, vulnerability assessment, encrypted secret storage, backup verification, disaster recovery procedures and continuous security auditing.

Overall, the implemented Terraform, Ansible and systemd hardening measures provide a secure, repeatable and maintainable deployment while establishing a strong foundation for future production improvements.