<h1 align="center">Automated LAMP Deployment with Bash + Real‑World Troubleshooting</h1>

<p align="center">
  <strong>Linux • Bash • Apache • MariaDB • PHP • Automation • Troubleshooting</strong>
</p>

---

## 🚀 Project Overview

This project focuses on automating the deployment of a **production‑ready LAMP stack** using a modular Bash script. The script installs and configures Linux, Apache, MariaDB, PHP, firewall rules, VirtualHosts, SSL certificates, and WordPress setup — all without manual intervention.

During deployment, the system encountered a real‑world failure where Apache refused to start. This led to a full troubleshooting workflow that mirrors what DevOps and Cloud engineers face in production environments.

---

## 🛠️ What the Script Automates

- Installation of Apache, MariaDB, PHP  
- UFW firewall configuration  
- VirtualHost creation  
- SSL certificate generation  
- WordPress database creation  
- Automated `wp-config.php` injection using Heredocs  
- Modular Bash functions for clean, reusable automation  

---

## ⚠️ The Core Challenge: Apache Would Not Start

After running the script, Apache failed with:

> **“Job for apache2.service failed.”**

Yet `apache2ctl configtest` returned:

> **“Syntax OK”**

This meant the configuration was valid — but something else was blocking Apache from starting.

---

## 🕵🏽‍♂️ Troubleshooting Workflow

A structured diagnostic process revealed the root cause:

### 🔍 1. Log Analysis  
Checked:
- `journalctl -xe`
- `/var/log/apache2/error.log`

### 🌐 2. Port Inspection  
Used:
- `sudo ss -tulpn`

### 💡 The Discovery  
**Nginx was already running and occupying Port 80**, preventing Apache from binding to it.

Web servers cannot share the same port — the first one wins.

---

## 🧠 Key Takeaways

- “Syntax OK” does not guarantee the environment is conflict‑free.  
- Always check for **port conflicts** when a service fails to start.  
- Logs + ports + service status = the fastest path to root cause.  
- Modular Bash scripting (functions + heredocs) makes automation clean and production‑ready.  

---

## 📸 Screenshots

Screenshots are stored in the `screenshots/` folder.

Example files:
- `apache-error.png`
- `port-conflict.png`
- `nginx-running.png`
- `resolved-apache-start.png`

---
