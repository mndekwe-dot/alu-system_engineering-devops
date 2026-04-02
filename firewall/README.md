# Firewall

## Task 0: Block all incoming traffic but

Configured UFW on **web-01** (44.203.152.117) to block all incoming traffic except the following TCP ports:

| Port | Service |
|------|---------|
| 22   | SSH |
| 80   | HTTP |
| 443  | HTTPS SSL |
| 8000 | Gunicorn (kora/jobs.imboni.tech backend) |

### Steps performed

1. Installed UFW on web-01
2. Set default policy to deny all incoming, allow all outgoing
3. Allowed ports 22, 80, 443, and 8000
4. Enabled UFW with `--force` flag (non-interactive)
5. Verified UFW status with `sudo ufw status verbose`
6. Verified kora app (jobs.imboni.tech) still responded HTTP 200 after enabling firewall

### Verification

Tested from lb-01 (44.202.26.45) before and after enabling UFW:

```bash
telnet 44.203.152.117 8000        # port open
curl -I http://44.203.152.117:8000 # HTTP 200 OK from gunicorn
curl -I https://jobs.imboni.tech   # HTTPS working via HAProxy
```

### File

- `0-block_all_incoming_traffic_but` — bash script with the UFW commands used
