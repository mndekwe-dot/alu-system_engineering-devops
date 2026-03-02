ALU System Engineering & DevOps — Complete Guide
Project Directory Structure

alu-system_engineering-devops/
├── README.md                    # Project overview
├── none                         # Duplicate SSH connect script
├── ssh/                         # SSH key management tasks
│   ├── 0-use_a_private_key      # Connect to server with private key
│   ├── 1-create_ssh_key_pair    # Generate RSA key pair
│   ├── 2-ssh_config             # SSH client config file
│   ├── authorized_keys          # Public key for server access
│   ├── school.pub               # Your generated public key
│   └── README.md
└── web_server/                  # Nginx web server tasks
    ├── 0-transfer_file          # Transfer files via SCP
    ├── 1-install_nginx_web_server  # Install & configure Nginx
    ├── 2-setup_a_domain_name    # Domain name setup
    ├── 3-redirection            # Add 301 redirect
    ├── 4-not_found_page_404     # Custom 404 page
    └── README.md
1. Creating an Ubuntu Server (AWS EC2)
Your server is at 44.203.152.117 (hosted on AWS). Here's how it was created:

Log in to AWS Console → EC2 → Launch Instance
Choose Ubuntu 20.04/22.04 LTS as the OS
Select instance type (e.g., t2.micro — free tier)
In Key Pair, create/download a .pem file — this is your private key
Set security group to allow SSH (port 22) and HTTP (port 80)
Launch the instance → get its public IP (your 44.203.152.117)
The server runs as user ubuntu by default on AWS.

2. Private Keys & Authorized Keys — How Authentication Works
This is the most important concept to understand:

How SSH Key Authentication Works

Your Computer                        Server (44.203.152.117)
─────────────                        ──────────────────────
~/.ssh/school        ←─ pair ─→      ~/.ssh/authorized_keys
(PRIVATE key)                        (PUBLIC key stored here)
    │
    └── You keep this secret,
        NEVER share it
The flow:

You try to connect: ssh -i ~/.ssh/school ubuntu@44.203.152.117
Server sends a challenge encrypted with your public key
Only your private key can decrypt it → you're authenticated
No password needed!
Your Project's SSH Files
File	What It Is	Purpose
ssh/1-create_ssh_key_pair	Script	Generates school (private) + school.pub (public) keys
ssh/school.pub	Public key	Goes into server's authorized_keys
ssh/authorized_keys	Public key	The key allowed to access the server
ssh/2-ssh_config	Config file	Tells SSH to always use school key, no password
ssh/0-use_a_private_key	Script	Connects to server using private key
Step-by-step: Setting Up Key Authentication
Step 1 — Generate your key pair (ssh/1-create_ssh_key_pair):


ssh-keygen -t rsa -b 4096 -N betty -f school
# Creates: school (private key) and school.pub (public key)
# Passphrase is "betty"
Step 2 — Copy private key to your SSH folder:


cp school ~/.ssh/school
chmod 600 ~/.ssh/school   # MUST be readable only by you
Step 3 — Add public key to server's authorized_keys:


# On the server, run:
echo "your-public-key-contents" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
Step 4 — Configure SSH client (ssh/2-ssh_config):


Host *
    IdentityFile ~/.ssh/school      # Always use this key
    PasswordAuthentication no       # Never use passwords
This file goes at ~/.ssh/config

Step 5 — Connect:


ssh -i ~/.ssh/school ubuntu@44.203.152.117
# Or just: ssh ubuntu@44.203.152.117  (if config file is set)
3. Transferring Files (Task 0)
File: web_server/0-transfer_file

scp (Secure Copy) transfers files over SSH. Your script:


./0-transfer_file FILE_PATH  IP  USERNAME  SSH_KEY_PATH
# Example:
./0-transfer_file myfile.txt 44.203.152.117 ubuntu ~/.ssh/school
What happens under the hood:


scp -o StrictHostKeyChecking=no -i ~/.ssh/school myfile.txt ubuntu@44.203.152.117:~/
Option	Meaning
-i ~/.ssh/school	Use this private key
-o StrictHostKeyChecking=no	Don't ask "are you sure?" for new hosts
ubuntu@44.203.152.117:~/	Destination: home folder on server
4. Installing Nginx (Tasks 1–4)
Nginx is a web server — it listens on port 80 and serves web pages.

Task 1 — Basic Installation (web_server/1-install_nginx_web_server)

# Run this ON the server (after SSH-ing in)
sudo ./1-install_nginx_web_server
What it does:

apt-get update — refreshes package list
apt-get install -y nginx — installs Nginx
Creates /var/www/html/index.html with "Holberton School"
Configures Nginx to listen on port 80
Restarts Nginx
After this, visiting http://44.203.152.117 shows "Holberton School"

Task 2 — Domain Name (web_server/2-setup_a_domain_name)
The file just contains YOURDOMAIN.tech — you need to:

Buy a .tech domain
In your DNS settings, add an A record: yourdomain.tech → 44.203.152.117
Replace YOURDOMAIN.tech with your real domain in this file
Task 3 — 301 Redirect (web_server/3-redirection)
A 301 redirect means "this URL has permanently moved." Visiting /redirect_me automatically sends users to YouTube:


http://44.203.152.117/redirect_me  →→→  https://youtube.com/...
The script adds this to Nginx config:


location /redirect_me {
    return 301 https://www.youtube.com/watch?v=QH2-TGUlwu4;
}
Task 4 — Custom 404 Page (web_server/4-not_found_page_404)
When someone visits a page that doesn't exist, instead of a generic error, they see "Ceci n'est pas une page" (French for "This is not a page").

The script:

Creates /var/www/html/404.html with that message
Adds error_page 404 /404.html; to Nginx config
5. Full Workflow — End to End

1. Create Ubuntu server on AWS
        ↓
2. Generate SSH keys locally (ssh/1-create_ssh_key_pair)
        ↓
3. Add public key to server's authorized_keys
        ↓
4. SSH into server (ssh/0-use_a_private_key)
        ↓
5. Transfer scripts to server (web_server/0-transfer_file)
        ↓
6. Run install script on server (web_server/1-install_nginx_web_server)
        ↓
7. Visit http://44.203.152.117 → see "Holberton School"
        ↓
8. Add redirect & 404 page (tasks 3 & 4)
Quick Reference Commands

# Connect to your server
ssh -i ~/.ssh/school ubuntu@44.203.152.117

# Transfer a file to server
./web_server/0-transfer_file myfile.txt 44.203.152.117 ubuntu ~/.ssh/school

# Install Nginx on server (run while SSH'd in)
sudo bash 1-install_nginx_web_server

# Check Nginx status on server
sudo service nginx status

# Restart Nginx on server
sudo service nginx restart