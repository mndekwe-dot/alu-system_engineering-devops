# DevOps Study Guide: Ubuntu, SSH, Nginx, DNS, and Bash Scripting

**Audience:** Beginners who have just completed their first DevOps project
**Project context:** Ubuntu server on AWS EC2 at `44.203.152.117`, domain `imboni.tech`, SSH user `ubuntu`, key at `~/.ssh/school`
**Date written:** 2026-03-02

---

## Table of Contents

1. [Ubuntu Server on AWS EC2](#1-ubuntu-server-on-aws-ec2)
2. [SSH (Secure Shell)](#2-ssh-secure-shell)
3. [SCP (Secure Copy)](#3-scp-secure-copy)
4. [Nginx Web Server](#4-nginx-web-server)
5. [Nginx Configuration](#5-nginx-configuration)
6. [DNS (Domain Name System)](#6-dns-domain-name-system)
7. [Bash Scripting for Server Configuration](#7-bash-scripting-for-server-configuration)
8. [Git Workflow Across Multiple Environments](#8-git-workflow-across-multiple-environments)

---

## 1. Ubuntu Server on AWS EC2

### What Is EC2?

Amazon EC2 (Elastic Compute Cloud) is a service that lets you rent v irtual computers — called **instances** — in Amazon's data centers. Instead of buying physical hardware, you pay for computing time. EC2 instances run in the cloud but behave exactly like real computers. You can install software on them, run web servers, and connect to them over the internet.

Think of an EC2 instance as a computer that lives in a data center somewhere in the world. You never physically touch it, but you can connect to it from anywhere using SSH.

**Key vocabulary:**
| Term | Meaning |
|------|---------|
| Instance | One virtual machine (a single "computer" you rented) |
| AMI | Amazon Machine Image — the operating system template (e.g., Ubuntu 22.04) |
| Region | Geographic location of the data center (e.g., us-east-1 = Virginia) |
| Security Group | Firewall rules controlling what traffic reaches your instance |
| Elastic IP | A fixed public IP address you can attach to an instance |
| Key Pair | The SSH key pair AWS generates (or accepts) when you create the instance |

### How to Launch an Instance (Step by Step)

1. Log in to the AWS Console at `console.aws.amazon.com`
2. Go to **EC2** > **Launch Instance**
3. Choose an AMI — for this project, **Ubuntu Server 22.04 LTS** (free tier eligible)
4. Choose an instance type — **t2.micro** is free tier eligible and sufficient for learning
5. Under **Key pair**: either create a new key pair (download the `.pem` file immediately — you cannot download it again) or use an existing one
6. Under **Network settings**, configure the Security Group (see below)
7. Click **Launch Instance**

After launching, AWS assigns the instance a **public IP address**. Your project server's public IP is `44.203.152.117`.

### Security Groups

A Security Group is a virtual firewall that controls which network traffic is allowed to reach your instance. Think of it as a list of rules: each rule says "allow traffic from X to port Y."

**Inbound rules you need for a web server:**

| Type | Protocol | Port | Source | Why |
|------|----------|------|--------|-----|
| SSH | TCP | 22 | Your IP (or 0.0.0.0/0) | Lets you connect via SSH |
| HTTP | TCP | 80 | 0.0.0.0/0 | Lets browsers load your website |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Lets browsers load your site securely (for later) |

**Important:** If you cannot SSH into your server, the most common reason (after a key problem) is that port 22 is not open in the Security Group.

### Ports 22 and 80 Explained

Ports are like numbered doors on a computer. When a program wants to communicate over the network, it "opens" a port and listens for incoming connections on that port. The port number tells the operating system which program should receive the incoming data.

- **Port 22** — SSH. When you run `ssh ubuntu@44.203.152.117`, your SSH client sends data to port 22 on the server. The SSH daemon (`sshd`) on the server listens on port 22 and handles the connection.
- **Port 80** — HTTP. When a browser loads `http://imboni.tech`, it connects to port 80 on the server. Nginx listens on port 80 and responds with web page content.

You can verify what is listening on which port with:
```bash
sudo ss -tlnp
# or
sudo netstat -tlnp
```

### Connecting to Your Remote Server

The basic command to connect:
```bash
ssh -i ~/.ssh/school ubuntu@44.203.152.117
```

Breaking this down:
- `ssh` — the SSH client program
- `-i ~/.ssh/school` — the `-i` flag means "identity file"; this specifies your private key
- `ubuntu` — the username on the remote server (Ubuntu EC2 instances default to the `ubuntu` user)
- `44.203.152.117` — the server's public IP address

After connecting you will see a prompt like `ubuntu@web-01:~$` — you are now running commands on the remote machine, not your local computer.

To disconnect:
```bash
exit
# or press Ctrl+D
```

### How It Connects to Other Topics

EC2 provides the server. SSH lets you connect to it. Nginx runs on it to serve web pages. DNS maps your domain name to its IP address. Everything in this project depends on understanding that EC2 is simply a remote computer with a public IP.

---

## 2. SSH (Secure Shell)

### What Is SSH?

SSH (Secure Shell) is a network protocol that lets you securely log in to a remote computer and run commands on it. "Secure" means all data sent between your computer and the server is **encrypted** — even if someone intercepts the network packets, they cannot read the contents.

Before SSH, system administrators used Telnet, which sent everything including passwords in plain text. SSH replaced Telnet by making the connection cryptographically secure.

### How SSH Works Under the Hood

SSH uses **asymmetric cryptography** (also called public-key cryptography). This is a mathematical system where two keys work as a pair:

1. A **private key** — kept secret on your local machine. Never share this.
2. A **public key** — can be freely shared. You put this on any server you want to access.

The keys are mathematically linked: anything encrypted with the public key can only be decrypted with the private key, and vice versa.

**The SSH handshake (simplified):**
1. Your SSH client connects to the server on port 22.
2. The server proves its identity using its own host key (this is what the "are you sure you want to continue connecting?" message is about).
3. Your client says "I want to log in as user `ubuntu`."
4. The server looks in `/home/ubuntu/.ssh/authorized_keys` for a public key that matches your private key.
5. The server sends a random challenge encrypted with your public key.
6. Only your private key can decrypt that challenge. Your client decrypts it and sends back a proof.
7. The server confirms the proof is correct and grants access — without a password ever being transmitted.

This is **passwordless authentication**, and it is both more secure and more convenient than passwords.

### Generating an SSH Key Pair

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Breaking this down:
- `ssh-keygen` — the key generation tool
- `-t ed25519` — the type of key; ed25519 is modern and recommended (RSA 4096 is also common)
- `-C "your_email@example.com"` — a comment added to the public key so you can identify it later

The command will ask:
```
Enter file in which to save the key (/home/user/.ssh/id_ed25519):
```
Press Enter for the default, or type a custom path like `/home/user/.ssh/school`.

```
Enter passphrase (empty for no passphrase):
```
A passphrase adds a layer of security — even if someone steals your private key file, they still need the passphrase. For learning environments it is fine to leave it empty.

This creates two files:
- `~/.ssh/school` — your **private key** (permissions must be 600)
- `~/.ssh/school.pub` — your **public key** (safe to share)

Check the contents of your public key:
```bash
cat ~/.ssh/school.pub
```
Output looks like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM... your_email@example.com
```

### What Is authorized_keys?

The file `/home/ubuntu/.ssh/authorized_keys` on the **server** is a list of public keys that are allowed to log in as that user. Each line is one public key.

To add your key manually:
```bash
# On the server:
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Paste your public key here, one per line
chmod 600 ~/.ssh/authorized_keys
```

Or use `ssh-copy-id` from your local machine:
```bash
ssh-copy-id -i ~/.ssh/school.pub ubuntu@44.203.152.117
```

**Permissions matter.** If the permissions are wrong, SSH will refuse to use the file:
```bash
chmod 700 ~/.ssh            # Directory: owner can read/write/enter
chmod 600 ~/.ssh/authorized_keys  # File: owner can read/write only
chmod 600 ~/.ssh/school     # Private key: owner can read/write only
```

### The SSH Config File

The SSH config file at `~/.ssh/config` lets you define shortcuts for SSH connections. Instead of typing the full command every time, you define a named host.

Example `~/.ssh/config`:
```
Host web-01
    HostName 44.203.152.117
    User ubuntu
    IdentityFile ~/.ssh/school
    StrictHostKeyChecking no
```

With this config, instead of:
```bash
ssh -i ~/.ssh/school ubuntu@44.203.152.117
```
You can type:
```bash
ssh web-01
```

**Fields explained:**
| Field | Meaning |
|-------|---------|
| `Host` | The alias/nickname you choose |
| `HostName` | The actual IP address or domain |
| `User` | The username to log in as |
| `IdentityFile` | Path to your private key |
| `StrictHostKeyChecking no` | Skips the "are you sure?" prompt for new hosts (convenient but slightly less secure) |

### Common SSH Errors and Fixes

**Error: `Permission denied (publickey)`**

This is the most common SSH error. It means the server rejected your key.

Possible causes and fixes:
1. **Wrong key file** — Make sure you are specifying the correct private key with `-i ~/.ssh/school`
2. **Key not in authorized_keys** — The public key corresponding to your private key is not in the server's `~/.ssh/authorized_keys`. Add it.
3. **Wrong permissions on private key** — If your private key permissions are too open, SSH refuses to use it.
   ```bash
   chmod 600 ~/.ssh/school
   ```
4. **Wrong username** — Ubuntu EC2 instances use `ubuntu`, not `root` or `ec2-user`.
5. **Wrong IP address** — Double-check the server IP.

To debug SSH connections, add `-v` (verbose) or `-vvv` (very verbose):
```bash
ssh -vvv -i ~/.ssh/school ubuntu@44.203.152.117
```
This prints every step of the handshake and usually tells you exactly why it failed.

**Error: `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`**

This means the server's host key changed (e.g., the instance was terminated and a new one launched with the same IP). Fix it:
```bash
ssh-keygen -R 44.203.152.117
```
This removes the old entry from `~/.ssh/known_hosts`.

**Error: `Connection refused`**

Port 22 is not open. Check:
- AWS Security Group inbound rules — is port 22 allowed?
- Is the instance actually running?
- Is the SSH service running on the server? (`sudo systemctl status ssh`)

**Error: `Connection timed out`**

Usually a network issue or the Security Group is blocking your IP. Try from a different network, or open port 22 to all IPs temporarily (`0.0.0.0/0`) to test.

### How SSH Connects to Other Topics

SSH is the foundation of everything. SCP uses SSH to transfer files. You connect to the EC2 instance via SSH to install Nginx, configure DNS, and run Bash scripts. The `authorized_keys` file you manage manually is the same mechanism AWS uses when it sets up your key pair at instance launch.

---

## 3. SCP (Secure Copy)

### What Is SCP?

SCP (Secure Copy Protocol) is a command-line tool that copies files between computers using SSH. It works exactly like the `cp` command for local files, but one of the paths is on a remote machine.

Because SCP uses SSH under the hood, it uses the same authentication (keys, `authorized_keys`) and the same encryption. If you can SSH into a server, you can SCP files to and from it.

### Command Structure

**Copy a file from your local machine to a remote server:**
```bash
scp -i ~/.ssh/school myfile.txt ubuntu@44.203.152.117:~/
```

Breaking this down:
- `scp` — the secure copy program
- `-i ~/.ssh/school` — same as SSH: specify the private key
- `myfile.txt` — the source file (local)
- `ubuntu@44.203.152.117:~/` — destination in the format `user@host:path`
  - `ubuntu` — remote username
  - `44.203.152.117` — remote server IP
  - `:~/` — the colon separates host from path; `~/` means the home directory of `ubuntu` on the server (`/home/ubuntu/`)

**Copy a file from the remote server to your local machine:**
```bash
scp -i ~/.ssh/school ubuntu@44.203.152.117:~/remotefile.txt ./localfile.txt
```
The source and destination are just swapped.

**Copy an entire directory (recursively):**
```bash
scp -r -i ~/.ssh/school ./mydir ubuntu@44.203.152.117:~/
```
The `-r` flag means recursive — copy the directory and all its contents.

### Important SCP Flags

| Flag | Meaning |
|------|---------|
| `-i identity_file` | Specify the private key to use |
| `-r` | Recursive copy (for directories) |
| `-P port` | Use a non-standard port (capital P, unlike ssh's lowercase -p) |
| `-o StrictHostKeyChecking=no` | Skip the known-hosts prompt (useful in scripts) |
| `-v` | Verbose output for debugging |

### The Project Script (Task 0)

The script `0-transfer_file` wraps SCP with argument validation:
```bash
#!/usr/bin/env bash
# Script to transfer a file to a server using scp

if [ $# -ne 4 ]; then
    echo "Usage: 0-transfer_file PATH_TO_FILE IP USERNAME PATH_TO_SSH_KEY"
    exit 1
fi

PATH_TO_FILE="$1"
IP="$2"
USERNAME="$3"
PATH_TO_SSH_KEY="$4"

scp -o StrictHostKeyChecking=no -i "$PATH_TO_SSH_KEY" "$PATH_TO_FILE" "${USERNAME}@${IP}:~/"
```

Usage:
```bash
./0-transfer_file myfile.txt 44.203.152.117 ubuntu ~/.ssh/school
```

**Why `-o StrictHostKeyChecking=no`?** In automated scripts, you do not want the script to pause and ask "Are you sure you want to connect to this new host?" This flag skips that prompt. In production environments with known servers this is acceptable; for unknown servers it reduces security.

### Common SCP Mistakes

1. **Forgetting the colon before the remote path** — `ubuntu@44.203.152.117~/` will fail; it must be `ubuntu@44.203.152.117:~/`
2. **Using lowercase `-p` for port** — SCP uses uppercase `-P` for port (SSH uses lowercase `-p`)
3. **Copying to a path you do not have permission to write to** — Always use `~/` (home directory) as the destination, then move the file with `sudo mv`

### How SCP Connects to Other Topics

SCP is how you get scripts from your local machine (or the GitHub sandbox) onto the EC2 server to run them. After editing a script locally, you SCP it to the server, then SSH in and execute it. SCP is also how you can back up server config files to your local machine.

---

## 4. Nginx Web Server

### What Is a Web Server?

A web server is a program that listens for HTTP requests on port 80 (and HTTPS on port 443) and responds with web page content. When you type `http://imboni.tech` in a browser:

1. Your browser looks up the IP address for `imboni.tech` using DNS (returns `44.203.152.117`)
2. Your browser connects to `44.203.152.117` on port 80
3. Your browser sends an HTTP request: `GET / HTTP/1.1`
4. Nginx (running on the server) receives the request
5. Nginx finds the appropriate file (e.g., `/var/www/html/index.html`)
6. Nginx sends back the file contents as an HTTP response
7. Your browser displays the page

### Installing Nginx

```bash
sudo apt-get update
sudo apt-get install -y nginx
```

- `apt-get update` — refreshes the list of available packages from Ubuntu's package repositories. This does NOT install or upgrade anything — it only updates the index. Always run this before installing packages so you get the latest version.
- `apt-get install -y nginx` — installs the Nginx package. The `-y` flag automatically answers "yes" to any confirmation prompts (necessary in scripts).
- `sudo` — runs the command as root (superuser), which is required for installing software.

After installation, Nginx starts automatically.

### Verifying Nginx Is Running

```bash
service nginx status
# or
systemctl status nginx
```

Test from the command line (does the server respond on port 80?):
```bash
curl http://localhost
# or
curl http://44.203.152.117
```

You should see HTML output (the default Nginx welcome page or your custom `index.html`).

### Default Configuration Location

After installing Nginx on Ubuntu, the important paths are:

| Path | Purpose |
|------|---------|
| `/etc/nginx/nginx.conf` | Main Nginx configuration file |
| `/etc/nginx/sites-available/` | Directory of available site configurations |
| `/etc/nginx/sites-enabled/` | Directory of active site configurations (symlinks to sites-available) |
| `/var/www/html/` | Default web root — files placed here are served by Nginx |
| `/var/log/nginx/access.log` | Log of all HTTP requests |
| `/var/log/nginx/error.log` | Log of Nginx errors — check this when things go wrong |

### How Nginx Serves Files

When Nginx receives an HTTP request for `/`, it:
1. Looks at its configuration to find the matching `server` block
2. Finds the `root` directive (e.g., `root /var/www/html`)
3. Looks for the requested path within that root
4. For `/`, it looks for the files listed in the `index` directive (e.g., `index.html`)
5. Returns the file to the client

So a request for `http://imboni.tech/` returns the contents of `/var/www/html/index.html`.

A request for `http://imboni.tech/about.html` returns `/var/www/html/about.html`.

### sites-available vs sites-enabled

Ubuntu's Nginx uses a pattern where:
- **sites-available** contains all your configuration files (active or not)
- **sites-enabled** contains only the configurations Nginx actually loads

`sites-enabled` holds **symbolic links** (shortcuts) pointing to files in `sites-available`. This lets you disable a site without deleting its config.

To enable a site:
```bash
sudo ln -s /etc/nginx/sites-available/mysite /etc/nginx/sites-enabled/mysite
```

To disable a site:
```bash
sudo rm /etc/nginx/sites-enabled/mysite
# (the original file in sites-available is untouched)
```

A fresh Nginx install creates `sites-available/default` and a symlink `sites-enabled/default` pointing to it.

### Starting and Restarting Nginx Without systemctl

The project uses `service nginx start` / `service nginx restart` instead of `systemctl`. Both work, but:

- `service nginx start` — uses the older SysVinit-compatible wrapper. This works even in Docker containers and environments where systemd is not running.
- `systemctl start nginx` — communicates directly with systemd, which requires systemd to be running.

In the ALU sandbox environment and some Docker containers, systemd is not available, which is why the project scripts use `service`.

```bash
service nginx start      # Start Nginx if it is not running
service nginx stop       # Stop Nginx
service nginx restart    # Stop then start Nginx (disconnects active connections)
service nginx reload     # Reload config without stopping (no connection interruption)
service nginx status     # Show whether Nginx is running
```

**When to use restart vs reload:**
- Use **restart** after installing Nginx or making major changes
- Use **reload** after editing a config file — it applies the new config without dropping connections

Always test your config before reloading:
```bash
sudo nginx -t
```
This parses the config and reports errors without actually applying them.

### How Nginx Connects to Other Topics

Nginx is the service that makes your EC2 server function as a web server. It reads its configuration (which you write in Bash scripts) and serves files from `/var/www/html/`. DNS points your domain to the server's IP, and then Nginx decides what to send back based on the request URL.

---

## 5. Nginx Configuration

### Server Block Structure

The Nginx configuration uses **server blocks** (similar to Apache's virtual hosts) to define how to handle requests. A server block groups all settings for one website or service.

The full default configuration from your project:
```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    error_page 404 /404.html;

    location /redirect_me {
        return 301 https://www.youtube.com/watch?v=QH2-TGUlwu4;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Directive-by-Directive Explanation

**`listen 80 default_server;`**

This tells Nginx to listen on port 80 (HTTP). The `default_server` flag means this server block handles requests that do not match any other server block — it is the fallback. You should only have one `default_server` per port.

**`listen [::]:80 default_server;`**

The same, but for IPv6 (`[::]` is the IPv6 wildcard address). Modern systems support both IPv4 and IPv6; this line enables IPv6 support.

**`root /var/www/html;`**

The filesystem directory from which Nginx serves files. A request for `/index.html` maps to the file `/var/www/html/index.html`.

**`index index.html index.htm index.nginx-debian.html;`**

When a request comes in for a directory (like `/`), Nginx looks for these files in order. If it finds `index.html`, it serves it. If not, it tries `index.htm`, then `index.nginx-debian.html`.

**`server_name _;`**

The `_` is a special wildcard that matches any hostname. It is used for the default server block when you do not have a specific domain. If you have a domain, you would write `server_name imboni.tech www.imboni.tech;`.

### Location Blocks

Location blocks match incoming request URLs and define how to handle them. Nginx checks location blocks in a specific order and uses the most specific match.

**Basic location:**
```nginx
location / {
    try_files $uri $uri/ =404;
}
```

**Exact match** (must match exactly):
```nginx
location = /favicon.ico {
    log_not_found off;
}
```

**Prefix match** (URL starts with this):
```nginx
location /images/ {
    root /var/www;
}
```

**Regex match** (case-sensitive):
```nginx
location ~ \.php$ {
    # handle PHP files
}
```

### The try_files Directive

```nginx
try_files $uri $uri/ =404;
```

`try_files` attempts to serve files in order and falls back to the last option:
1. `$uri` — try to find a file matching the requested URI exactly (e.g., `/about.html` → `/var/www/html/about.html`)
2. `$uri/` — try to find a directory matching the URI (e.g., `/about/` → `/var/www/html/about/`)
3. `=404` — if neither exists, return a 404 error response

The `$uri` is an Nginx variable that holds the path portion of the request URL.

### 301 Redirect

```nginx
location /redirect_me {
    return 301 https://www.youtube.com/watch?v=QH2-TGUlwu4;
}
```

**HTTP 301** means "Moved Permanently." When a browser requests `/redirect_me`, Nginx responds with:
```
HTTP/1.1 301 Moved Permanently
Location: https://www.youtube.com/watch?v=QH2-TGUlwu4
```

The browser then automatically follows the redirect and loads the new URL. The "301" status code is important — it tells browsers and search engines this redirect is permanent, so they update their bookmarks and index the new URL.

**301 vs 302:**
- **301** — Permanent redirect. Browsers cache it. Search engines transfer "SEO value" to the new URL.
- **302** — Temporary redirect. Browsers do not cache it. Use this if the redirect might change.

### Custom 404 Error Page

```nginx
error_page 404 /404.html;
```

This tells Nginx: when a 404 error occurs (file not found), instead of showing the default Nginx 404 page, serve the file at `/404.html` (which maps to `/var/www/html/404.html`).

You can customize error pages for any HTTP status code:
```nginx
error_page 403 /403.html;
error_page 500 502 503 504 /50x.html;
```

### Testing Config and Common Mistakes

Always test your config before applying it:
```bash
sudo nginx -t
```

Good output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Common configuration mistakes:**

1. **Missing semicolons** — Every directive must end with `;`. Forgetting one causes a parse error.
   ```nginx
   root /var/www/html   # WRONG - missing semicolon
   root /var/www/html;  # CORRECT
   ```

2. **Missing closing braces** — Every `{` must have a matching `}`. Count them.

3. **Two default_server blocks** — Only one server block per port can be `default_server`. Remove `default_server` from one of them.

4. **Wrong root path** — If the root directory does not exist or Nginx cannot read it, all requests return 403 or 404. Verify with `ls /var/www/html/`.

5. **Forgetting to reload after changes** — Edit the config, test with `nginx -t`, then run `service nginx reload`. Without this step, the old config is still active.

### Full Annotated Example (Task 4 Script)

Here is the complete Nginx config from the project with annotations:
```nginx
server {
    # Listen on port 80 (HTTP) for IPv4 and IPv6
    listen 80 default_server;
    listen [::]:80 default_server;

    # Serve files from this directory
    root /var/www/html;

    # Try these filenames when a directory is requested
    index index.html index.htm index.nginx-debian.html;

    # Match any hostname (wildcard)
    server_name _;

    # Serve /var/www/html/404.html when a 404 occurs
    error_page 404 /404.html;

    # Permanently redirect /redirect_me to YouTube
    location /redirect_me {
        return 301 https://www.youtube.com/watch?v=QH2-TGUlwu4;
    }

    # For all other requests, try to find a matching file
    # If no file found, return 404
    location / {
        try_files $uri $uri/ =404;
    }
}
```

---

## 6. DNS (Domain Name System)

### What Is DNS?

DNS (Domain Name System) is the internet's phone book. Computers communicate using IP addresses (like `44.203.152.117`), but humans remember domain names (like `imboni.tech`). DNS translates domain names into IP addresses.

When you type `http://imboni.tech` in your browser:
1. Your browser asks your computer's **DNS resolver** (usually your router or your ISP): "What is the IP address for imboni.tech?"
2. If the resolver does not know, it asks a **root nameserver**
3. The root nameserver says "for `.tech` domains, ask the `.tech` TLD nameserver"
4. The TLD nameserver says "for `imboni.tech`, ask the nameserver at `ns1.yourdomain-registrar.com`"
5. That nameserver returns: "imboni.tech points to `44.203.152.117`"
6. Your browser connects to `44.203.152.117` on port 80

This whole process typically takes milliseconds.

### DNS Record Types

| Record Type | Purpose | Example |
|-------------|---------|---------|
| **A** | Maps a domain to an IPv4 address | `imboni.tech → 44.203.152.117` |
| **AAAA** | Maps a domain to an IPv6 address | `imboni.tech → 2001:db8::1` |
| **CNAME** | Alias — maps one domain to another domain | `www.imboni.tech → imboni.tech` |
| **MX** | Mail server for the domain | `imboni.tech → mail.example.com` |
| **TXT** | Arbitrary text — used for verification, SPF | `"v=spf1 include:..."` |
| **NS** | Nameservers responsible for the domain | `imboni.tech → ns1.registrar.com` |

**For this project, you only need an A record:**

| Name | Type | Value | TTL |
|------|------|-------|-----|
| imboni.tech | A | 44.203.152.117 | 3600 |

This A record tells the world: "The IP address for imboni.tech is 44.203.152.117."

### Domain Registrars

A domain registrar is a company authorized to register domain names. To own `imboni.tech`, you purchase it from a registrar (e.g., Namecheap, GoDaddy, Google Domains, .tech Domains). Once you own it, you manage its DNS records through the registrar's control panel.

For the project domain `imboni.tech`, the A record was configured through the registrar's DNS management panel to point to `44.203.152.117`.

### DNS Propagation

When you create or change a DNS record, the change does not take effect instantly everywhere. DNS records have a **TTL (Time To Live)** — a number in seconds telling resolvers how long to cache the record. If the TTL is 3600 (one hour), resolvers will use the old value for up to one hour before re-checking.

**DNS propagation** is the time it takes for DNS changes to spread across all DNS servers worldwide. This can take from a few minutes to 48 hours, depending on the TTL and caching.

This is why the project checker might not immediately see your domain working after you set it up — you may need to wait for propagation.

### The dig Command

`dig` (Domain Information Groper) is the essential DNS debugging tool. It lets you query DNS servers directly and see what records they return.

**Basic usage:**
```bash
dig imboni.tech
```

Output:
```
; <<>> DiG 9.18.1 <<>> imboni.tech
;; ANSWER SECTION:
imboni.tech.        3600    IN    A    44.203.152.117
```

Reading the output:
- `imboni.tech.` — the queried domain (the trailing dot is how DNS represents the root)
- `3600` — TTL in seconds (1 hour)
- `IN` — Internet class (always IN for regular records)
- `A` — record type
- `44.203.152.117` — the IP address

**Query a specific record type:**
```bash
dig imboni.tech A      # Query A records
dig imboni.tech MX     # Query mail records
dig imboni.tech NS     # Query nameservers
```

**Query a specific DNS server (bypass your cache):**
```bash
dig @8.8.8.8 imboni.tech    # Use Google's public DNS
dig @1.1.1.1 imboni.tech    # Use Cloudflare's public DNS
```

**Short output (just the answer):**
```bash
dig +short imboni.tech
# Returns: 44.203.152.117
```

### WHOIS

WHOIS is a protocol for querying domain registration information — who owns the domain, when it expires, what nameservers it uses.

```bash
whois imboni.tech
```

Output includes:
- Registrar (who the domain was purchased from)
- Expiration date
- Nameservers
- Registrant contact (often private/redacted for privacy)

To check if a domain is registered and see its nameservers (which determines where DNS records are managed):
```bash
whois imboni.tech | grep -i nameserver
```

### Verifying Your Domain Points to the Right IP

Step-by-step verification:
```bash
# 1. Check what IP your domain resolves to
dig +short imboni.tech

# 2. Verify that IP is your server's IP
# Expected output: 44.203.152.117

# 3. Test that your web server responds at that domain
curl -v http://imboni.tech

# 4. Check the HTTP response headers
curl -I http://imboni.tech

# 5. Check propagation from multiple locations using an online tool
# https://www.whatsmydns.net/ — enter imboni.tech and select A record
```

### How DNS Connects to Other Topics

DNS is the bridge between your human-readable domain (`imboni.tech`) and your EC2 server's IP (`44.203.152.117`). Nginx on the server receives the HTTP request but does not need to know anything about DNS — that resolution happened before the connection reached the server. In Task 2 of the project, the domain name (just `imboni.tech`) is stored in a file so the checker can verify you have configured your DNS correctly.

---

## 7. Bash Scripting for Server Configuration

### Why Bash Scripts?

Instead of manually SSHing into the server and running commands one by one, you write a Bash script that runs all the commands automatically. Benefits:
- **Reproducible** — the script produces the same result every time
- **Documentable** — the script is readable code that explains what was done
- **Automatable** — you can run the script on multiple servers or at any time
- **Testable** — automated checkers can run the script and verify the result

### Script Structure

Every script in this project starts with:
```bash
#!/usr/bin/env bash
# Brief description of what this script does
```

- `#!/usr/bin/env bash` — the **shebang line**. Tells the OS which interpreter to use. `/usr/bin/env bash` finds the `bash` binary in the PATH, making the script more portable than `#!/bin/bash` (which hard-codes the path).
- Comments (`#`) explain the purpose of each section. The checker graders read your scripts — clear comments matter.

### Making Scripts Executable

Before running a script, make it executable:
```bash
chmod +x ./1-install_nginx_web_server
./1-install_nginx_web_server
```

Or run it directly with bash:
```bash
bash 1-install_nginx_web_server
```

`chmod +x` adds execute permission. Without it, you get `Permission denied`.

### Writing Idempotent Scripts

**Idempotent** means running the script multiple times produces the same result as running it once. This is a critical property for server configuration scripts.

**Why idempotency matters:**
- If the script fails halfway through, you can re-run it without breaking things
- Automated systems may run your script multiple times
- You can run it on a server that already has some configuration and it should still work correctly

**Example — NOT idempotent:**
```bash
echo "export PATH=/usr/local/bin:$PATH" >> ~/.bashrc
# Every time you run this, it adds another line to .bashrc
# After 5 runs: 5 duplicate lines
```

**Idempotent version:**
```bash
grep -q 'PATH=/usr/local/bin' ~/.bashrc || echo "export PATH=/usr/local/bin:$PATH" >> ~/.bashrc
# Only adds the line if it does not already exist
```

The project scripts achieve idempotency because:
- `apt-get install nginx` — installing an already-installed package does nothing
- `echo "..." > /var/www/html/index.html` — overwrites the file (no duplicates)
- `cat > /etc/nginx/sites-available/default << 'EOF'` — overwrites the entire config (no duplicates)

### Why cat Heredoc Is Better Than sed for Config Rewrites

**The problem with sed:** When modifying configuration files, `sed` makes targeted replacements — change this line to that. This works when the config has a known structure, but has problems:
- Fragile — if the existing file differs from what you expect, the replacement can fail silently
- Hard to read — regex replacements are hard to understand
- Hard to verify — what does the config look like after multiple sed operations?

**The cat heredoc approach:** Instead of modifying the existing file, you replace it entirely with a known-good configuration:

```bash
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
```

Breaking this down:
- `cat >` — run `cat` and redirect its output into a file (overwriting any existing content)
- `/etc/nginx/sites-available/default` — the target file to write
- `<< 'EOF'` — start of a **heredoc** (here document). Everything until the line containing just `EOF` is treated as the content to write.
- The single quotes around `'EOF'` are **critical**: they prevent variable expansion inside the heredoc. Without quotes (`<< EOF`), `$uri` would be treated as a shell variable and replaced with an empty string, breaking the Nginx config.
- `EOF` — end of the heredoc (must be on its own line with no leading whitespace)

**Advantages of cat heredoc:**
1. The final config is completely visible in the script — no guessing what it looks like
2. It is idempotent — running it again produces the same file
3. No regex — what you see is what you get
4. Easy to add or remove lines from the config

### CRLF Line Endings Issue on Windows

This is one of the most common and confusing errors for Windows users working with Linux servers.

**The problem:** Windows uses two characters to mark the end of a line: `\r\n` (carriage return + line feed). Linux uses only `\n` (line feed). When you write a Bash script in Windows and transfer it to a Linux server, the Windows line endings cause the script to fail with strange errors like:
```
bash: ./myscript: /bin/bash^M: bad interpreter: No such file or directory
```

The `^M` is the carriage return character (`\r`) being displayed visibly.

**How to detect it:**
```bash
file myscript
# Output: myscript: Bourne-Again shell script, ASCII text, with CRLF line terminators
```
The key phrase is "with CRLF line terminators" — this script will fail.

**How to fix it on the server:**
```bash
# Method 1: dos2unix (most straightforward)
sudo apt-get install dos2unix
dos2unix myscript

# Method 2: sed
sed -i 's/\r//' myscript

# Method 3: tr
tr -d '\r' < myscript > myscript_fixed && mv myscript_fixed myscript
```

**How to prevent it in VSCode:**
- Look at the bottom-right of the VSCode window — it shows `CRLF` or `LF`
- Click on `CRLF` and change it to `LF`
- Or add to your VSCode settings (`settings.json`): `"files.eol": "\n"`
- Or configure Git to not convert line endings: `git config core.autocrlf false`

### service vs systemctl vs reload

Understanding these commands prevents breaking a running server:

```bash
service nginx start      # Start Nginx (only if stopped)
service nginx stop       # Stop Nginx (kills all connections)
service nginx restart    # Stop + Start (brief downtime, drops connections)
service nginx reload     # Re-read config without stopping (no downtime)
service nginx status     # Show current state
```

**reload vs restart:**
- `reload` sends the SIGHUP signal to Nginx. Nginx re-reads its config files and gracefully applies them. Existing connections are not dropped.
- `restart` stops the Nginx process and starts a fresh one. Any currently-served requests are dropped.

**In production:** always use `reload` after config changes. Only use `restart` if Nginx is in a bad state or after major changes (like installing modules).

**In scripts:** use `restart` after initial installation, since there are no existing connections to worry about.

### Argument Handling and Validation

From Task 0, the pattern for handling script arguments:
```bash
if [ $# -ne 4 ]; then
    echo "Usage: 0-transfer_file PATH_TO_FILE IP USERNAME PATH_TO_SSH_KEY"
    exit 1
fi

PATH_TO_FILE="$1"
IP="$2"
USERNAME="$3"
PATH_TO_SSH_KEY="$4"
```

- `$#` — the number of arguments passed to the script
- `-ne 4` — "not equal to 4"
- `exit 1` — exit with error code 1 (non-zero exit codes indicate failure)
- `$1`, `$2`, `$3`, `$4` — the first, second, third, fourth arguments
- Assigning to named variables (`PATH_TO_FILE="$1"`) makes the code readable

**Always quote your variables:** Use `"$variable"` not `$variable`. If the value contains spaces, unquoted variables split into multiple arguments:
```bash
FILE="my file.txt"
scp $FILE server:~/        # WRONG: scp sees two args: "my" and "file.txt"
scp "$FILE" server:~/      # CORRECT: scp sees one arg: "my file.txt"
```

### Common Bash Scripting Mistakes

1. **Missing `#!/usr/bin/env bash`** — Without the shebang, the script may run with `/bin/sh` instead of bash, which does not support all bash features.

2. **Not making the script executable** — `chmod +x script` or run with `bash script`.

3. **CRLF line endings** — Covered above. Use `dos2unix`.

4. **Forgetting `sudo`** — Commands that write to `/etc/` or install packages need root. The checker typically runs scripts as root, but when testing manually, prefix with `sudo`.

5. **Not quoting variables** — `"$variable"` not `$variable`.

6. **Wrong heredoc quoting** — `<< 'EOF'` (quoted) prevents variable expansion; `<< EOF` (unquoted) allows it. Use quoted when writing Nginx configs that contain `$uri`.

7. **Using `>>` instead of `>`** — `>>` appends, `>` overwrites. For config files, use `>` to ensure a clean write every time.

---

## 8. Git Workflow Across Multiple Environments

### The Three Environments

In this project, work happens in three different places:

| Environment | Description | How to get code here |
|-------------|-------------|---------------------|
| **Local machine** (Windows + VSCode) | Where you write and edit code | The original source |
| **GitHub (remote repo)** | Central storage, accessible from anywhere | `git push` from local |
| **Web terminal sandbox** | ALU's browser-based Linux environment | `git pull` or `git clone` from GitHub |
| **EC2 server** (web-01) | The production server at `44.203.152.117` | `scp` or `git pull` from GitHub |

The checker runs on the EC2 server. It executes your scripts and verifies the results. This means:

**The code must be on GitHub for the checker to work correctly, AND the scripts must be executable on the server.**

### The Full Workflow

```
Edit (VSCode) → git add → git commit → git push
                                              ↓
                                         GitHub
                                              ↓
         SSH into server → git pull (if git is set up on server)
         OR
         SCP the script directly to the server → run it
```

**Practical step-by-step for each task:**

```bash
# 1. Write or edit the script in VSCode on Windows

# 2. Check line endings (bottom right of VSCode) — must be LF, not CRLF

# 3. Stage and commit your changes
git add web_server/1-install_nginx_web_server
git commit -m "Add nginx installation script"

# 4. Push to GitHub
git push origin main

# 5. Transfer the script to the server (if needed for manual testing)
scp -i ~/.ssh/school web_server/1-install_nginx_web_server ubuntu@44.203.152.117:~/

# 6. SSH into the server
ssh -i ~/.ssh/school ubuntu@44.203.152.117

# 7. On the server: make executable and run
chmod +x ~/1-install_nginx_web_server
sudo ./1-install_nginx_web_server

# 8. Verify the result
curl http://localhost
```

### Why Files Must Be Committed and Pushed

The ALU checker does not look at your local files or even your server's files directly. It:
1. Clones or pulls your GitHub repository
2. Checks that the required files exist with the correct names
3. May execute the scripts and verify the server state

If you have a working script on your server but never committed it to GitHub, the checker will not find it and will mark the task as failed.

**This means:** every change you make should be committed and pushed to GitHub, even if you are also running the script manually on the server.

### Keeping Environments in Sync

A common problem: you make changes in one environment but forget to propagate them to others.

**Scenario:** You edit a script in the sandbox web terminal, test it on the server, it works — but you forget to commit and push. You close the browser tab. The sandbox session expires. Your changes are gone.

**Prevention:**
- Treat GitHub as the single source of truth
- Push to GitHub before closing any terminal or browser tab
- When starting a new session (whether on Windows, sandbox, or server), always `git pull` first

**Scenario:** You push from Windows but the sandbox has local changes from a previous session. When you pull, Git complains about conflicts.

**Fix:**
```bash
git status          # See what is different
git diff            # See the actual changes
git stash           # Temporarily save local changes
git pull            # Get the latest from GitHub
git stash pop       # Re-apply your saved changes
```

### Connecting Scripts to the Checker

The project checker (Holberton/ALU's automated grader) typically does the following:
1. Reads the file from your GitHub repository (e.g., `web_server/0-transfer_file`)
2. Checks the file exists and has executable permissions committed (visible via `git ls-files --stage`)
3. May run the script against a fresh server and check the output

**Important file permission in Git:**

Git tracks the executable bit. When you run `chmod +x script` and then commit, Git stores that the file is executable. On a Linux system that clones the repo, the file will be executable. On Windows, `chmod` does not work the same way — but you can tell Git to track the permission:

```bash
git update-index --chmod=+x web_server/1-install_nginx_web_server
git commit -m "Set executable permission on install script"
```

### Using the Web Terminal Sandbox

The ALU sandbox provides a Linux terminal in the browser. It behaves like a real Ubuntu machine. To work efficiently:

```bash
# Clone your repo (first time)
git clone https://github.com/yourusername/alu-system_engineering-devops.git

# Navigate to the right directory
cd alu-system_engineering-devops/web_server/

# Make your script executable
chmod +x 1-install_nginx_web_server

# Test it (sandbox has a different server from web-01, but good for testing syntax)
sudo ./1-install_nginx_web_server

# If you made changes in the sandbox, push them
git add .
git commit -m "Fix script"
git push origin main
```

**Warning about sandbox sessions:** Sandbox environments are temporary. Files created outside the cloned git repo will be lost when the session ends. Always commit your work.

### Summary: The Mental Model

Think of it this way:
- **VSCode** is your workshop — where you build things
- **Git/GitHub** is your warehouse — where you store and version everything
- **The server** is your production facility — where your code actually runs
- **SCP** and `git pull` are the trucks that move code between warehouse and production

The golden rule: **the warehouse (GitHub) always has the canonical version**. Everything else is a copy.

---

## Quick Reference: Essential Commands

### SSH and SCP
```bash
# Connect to server
ssh -i ~/.ssh/school ubuntu@44.203.152.117

# Connect using SSH config alias
ssh web-01

# Copy file to server
scp -i ~/.ssh/school localfile.txt ubuntu@44.203.152.117:~/

# Copy file from server
scp -i ~/.ssh/school ubuntu@44.203.152.117:~/remotefile.txt ./

# Generate SSH key pair
ssh-keygen -t ed25519 -C "email@example.com" -f ~/.ssh/school

# Debug SSH connection
ssh -vvv -i ~/.ssh/school ubuntu@44.203.152.117

# Remove old known host entry
ssh-keygen -R 44.203.152.117
```

### Nginx
```bash
# Install
sudo apt-get update && sudo apt-get install -y nginx

# Test configuration syntax
sudo nginx -t

# Start / Stop / Restart / Reload
sudo service nginx start
sudo service nginx stop
sudo service nginx restart
sudo service nginx reload

# Check if running
sudo service nginx status

# View error log
sudo tail -f /var/log/nginx/error.log

# View access log
sudo tail -f /var/log/nginx/access.log

# Test web server response
curl http://localhost
curl -I http://44.203.152.117   # Headers only
```

### DNS
```bash
# Look up A record
dig imboni.tech A

# Short output (just the IP)
dig +short imboni.tech

# Query using Google DNS (bypass local cache)
dig @8.8.8.8 imboni.tech

# Check domain registration
whois imboni.tech

# Test HTTP response via domain
curl http://imboni.tech
```

### Bash / Linux
```bash
# Make script executable
chmod +x myscript

# Fix CRLF line endings
dos2unix myscript
# or
sed -i 's/\r//' myscript

# Check file type / line endings
file myscript

# View file with special characters visible
cat -A myscript    # ^M at end of lines = CRLF problem

# Run script as root
sudo ./myscript

# Check what is listening on ports
sudo ss -tlnp
```

### Git
```bash
# Check status
git status

# Stage specific file
git add web_server/1-install_nginx_web_server

# Commit
git commit -m "Add nginx installation script"

# Push to GitHub
git push origin main

# Pull latest from GitHub
git pull origin main

# Set executable bit in Git (for scripts)
git update-index --chmod=+x web_server/1-install_nginx_web_server

# Stash local changes before pulling
git stash
git pull
git stash pop
```

---

## Topic Interconnection Map

```
GitHub (source of truth)
    |
    |--- git push/pull ---+
    |                     |
    |              Web Terminal Sandbox
    |              (Linux environment)
    |                     |
    |--- git clone    chmod +x / test scripts
    |
Windows (VSCode)
    |
    +--- scp -i ~/.ssh/school script ubuntu@44.203.152.117:~/
    |
    v
EC2 Instance (44.203.152.117)
    |
    +--- SSH daemon (port 22) ← you connect via: ssh -i ~/.ssh/school ubuntu@...
    |       |
    |       +--- ~/.ssh/authorized_keys (contains your public key)
    |
    +--- Nginx (port 80) ← browsers connect here
    |       |
    |       +--- /etc/nginx/sites-available/default (your config)
    |       +--- /var/www/html/index.html (your content)
    |
    +--- DNS maps: imboni.tech → 44.203.152.117
            |
            +--- A record set at domain registrar
            +--- verify with: dig +short imboni.tech
            +--- propagation: wait up to 48h after changes
```

---

## Exam Preparation Checklist

### Ubuntu / EC2
- [ ] Explain what an EC2 instance is and how it differs from a physical server
- [ ] List the Security Group rules needed for an SSH + HTTP server
- [ ] Explain why port 22 and port 80 matter

### SSH
- [ ] Explain how public-key authentication works without memorizing math — just the concept
- [ ] Show how to generate a key pair with `ssh-keygen`
- [ ] Explain what `authorized_keys` is and where it lives
- [ ] Write an `~/.ssh/config` entry for `web-01`
- [ ] Diagnose and fix `Permission denied (publickey)` in 3 different ways

### SCP
- [ ] Write the SCP command to transfer `myfile.txt` to `~/` on `web-01`
- [ ] Explain what `-o StrictHostKeyChecking=no` does and when to use it
- [ ] Explain the difference between the source and destination argument formats

### Nginx
- [ ] List the four key Nginx directories/files and their purposes
- [ ] Explain the difference between `sites-available` and `sites-enabled`
- [ ] Explain when to use `reload` vs `restart`
- [ ] Write the command to test Nginx config syntax

### Nginx Config
- [ ] Write a complete server block from memory
- [ ] Explain `listen 80 default_server`
- [ ] Explain `try_files $uri $uri/ =404`
- [ ] Write a 301 redirect for `/redirect_me`
- [ ] Write an `error_page 404` directive

### DNS
- [ ] Explain the difference between an A record and a CNAME record
- [ ] Use `dig` to verify a domain points to the correct IP
- [ ] Explain DNS propagation and why changes are not instant

### Bash Scripting
- [ ] Explain idempotency and why it matters
- [ ] Explain why `cat > file << 'EOF'` is better than `sed` for config rewrites
- [ ] Explain the CRLF problem and how to detect and fix it
- [ ] Explain the difference between `service nginx restart` and `service nginx reload`

### Git Workflow
- [ ] Explain why code must be on GitHub for the checker to work
- [ ] Describe the full flow from editing a script to it running on the server
- [ ] Explain how to set the executable bit in Git for a script

---

---

## 9. Load Balancing & HAProxy

### What Is a Load Balancer?

A load balancer sits in front of multiple servers and distributes incoming traffic between them. Instead of one server handling everything, two or more servers share the load.

```
User Request
     ↓
Load Balancer (lb-01: 44.202.26.45)
     ↓            ↓
  web-01        web-02
(44.203.152.117) (54.167.139.121)
```

**Why it matters:**
- **Redundancy** — if web-01 crashes, web-02 keeps serving
- **Scalability** — double the servers = double the capacity
- **Reliability** — users never notice one server going down

### HAProxy

HAProxy (High Availability Proxy) is the most popular open-source load balancer. It runs on lb-01 and decides which backend server handles each request.

**Install HAProxy:**
```bash
apt-get -y install software-properties-common
add-apt-repository ppa:vbernat/haproxy-1.8
apt-get update
apt-get -y install haproxy
```

### HAProxy Configuration

The config file lives at `/etc/haproxy/haproxy.cfg`. You append your settings to it:

```
listen 7058-webs
    bind *:80              ← listen on all interfaces, port 80
    mode http              ← HTTP mode (not TCP)
    balance roundrobin     ← algorithm: take turns
    server 7058-web-01 44.203.152.117:80 check   ← web-01
    server 7058-web-02 54.167.139.121:80 check   ← web-02
```

| Directive | Meaning |
|---|---|
| `listen` | Combines frontend + backend in one block |
| `bind *:80` | Accept traffic on port 80 from any IP |
| `balance roundrobin` | Alternate requests between servers equally |
| `server name IP:port check` | Define a backend server, `check` = health check |

### Round Robin Algorithm

```
Request 1 → web-01
Request 2 → web-02
Request 3 → web-01
Request 4 → web-02
...and so on
```

Simple, fair, and effective when both servers have equal capacity.

### Managing HAProxy via Init Script

The task requires HAProxy to be manageable via an init script (not just systemctl):

```bash
echo "ENABLED=1" >> /etc/default/haproxy   # enable init script
service haproxy restart                      # start/restart HAProxy
```

---

## 10. Custom HTTP Response Headers

### What Is an HTTP Header?

When a server responds to a browser, it sends two parts:
1. **Headers** — metadata (status, content type, custom info)
2. **Body** — the actual HTML/content

```
HTTP/1.1 200 OK
Server: nginx/1.18.0
X-Served-By: 7058-web-01     ← custom header
Content-Type: text/html

<html>Holberton School</html>
```

### The X-Served-By Header

When you have a load balancer, you can't tell which server handled a request just by looking at the response. The `X-Served-By` header solves this — each server adds its own hostname to every response.

**In nginx config:**
```nginx
add_header X-Served-By $hostname;
```

`$hostname` is nginx's built-in variable — it automatically contains the server's hostname at request time.

**Why `$hostname` not `$HOSTNAME`:**
| Variable | Context | Value |
|---|---|---|
| `$HOSTNAME` | Bash environment variable (uppercase) | Set at shell start |
| `$hostname` | Nginx built-in variable (lowercase) | Evaluated at request time |

In the nginx config file, you need nginx's `$hostname`. In a bash double-quoted string, you write `\$hostname` so bash doesn't try to expand it — the backslash tells bash "leave this for nginx to handle".

**Verify the header:**
```bash
curl -sI http://44.203.152.117 | grep X-Served-By
# X-Served-By: 7058-web-01

curl -sI http://54.167.139.121 | grep X-Served-By
# X-Served-By: 7058-web-02
```

**Verify through load balancer (alternates each time):**
```bash
curl -sI http://44.202.26.45 | grep X-Served-By
# X-Served-By: 7058-web-01
curl -sI http://44.202.26.45 | grep X-Served-By
# X-Served-By: 7058-web-02
```

---

## 11. Multiple Server Environments

### Your Infrastructure

```
Internet
    ↓
imboni.tech → 44.202.26.45 (DNS A record)
    ↓
7058-lb-01 (44.202.26.45) — HAProxy load balancer
    ↓ round-robin ↓
7058-web-01              7058-web-02
(44.203.152.117)         (54.167.139.121)
  - Nginx port 80          - Nginx port 80
  - Holberton School       - Holberton School
  - X-Served-By header     - X-Served-By header
  - resume.imboni.tech
```

### Connecting to Each Server

| Server | SSH Command |
|---|---|
| web-01 | `ssh -i ~/.ssh/school ubuntu@44.203.152.117` |
| web-02 | `ssh -i ~/.ssh/school ubuntu@54.167.139.121` |
| lb-01  | `ssh -i ~/.ssh/school ubuntu@44.202.26.45` |

All use passphrase: `betty`

### Transferring Files to Any Server

```bash
# From webterm, using the 0-transfer_file script:
cd /alu-system_engineering-devops/web_server

./0-transfer_file ../load_balancer/0-custom_http_response_header 44.203.152.117 ubuntu ~/.ssh/school
./0-transfer_file ../load_balancer/0-custom_http_response_header 54.167.139.121 ubuntu ~/.ssh/school
./0-transfer_file ../load_balancer/1-install_load_balancer 44.202.26.45 ubuntu ~/.ssh/school
```

### Key Lesson: SSH Key Must Exist on Every Server

When you add a new server (web-02, lb-01), your public key is NOT automatically there. You must add it manually via **AWS EC2 Instance Connect** first:

1. AWS Console → EC2 → select instance → Connect → EC2 Instance Connect
2. In browser terminal: `echo "your-school.pub-content" >> ~/.ssh/authorized_keys`
3. Now `ssh -i ~/.ssh/school ubuntu@NEW_SERVER_IP` works

---

## Updated Exam Checklist

### Load Balancing
- [ ] Explain what a load balancer does and why it's needed
- [ ] Explain the round-robin algorithm
- [ ] Write a HAProxy listen block for two backend servers
- [ ] Explain what `balance roundrobin` means
- [ ] Explain what `server name IP:port check` does

### Custom HTTP Headers
- [ ] Explain what HTTP headers are
- [ ] Write the nginx directive to add `X-Served-By` header
- [ ] Explain the difference between `$hostname` (nginx) and `$HOSTNAME` (bash)
- [ ] Verify a custom header using `curl -sI URL | grep X-Served-By`
- [ ] Explain why X-Served-By is useful with a load balancer

### Multi-Server Management
- [ ] List all 3 servers with their IPs and roles
- [ ] Explain how to add SSH key access to a new server
- [ ] Describe the full flow to deploy a script to all 3 servers

---

*End of Study Guide*
