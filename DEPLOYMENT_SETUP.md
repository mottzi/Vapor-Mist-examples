# Deployment Setup Guide

This guide details the changes required to support the new "Sidecar" Deployer Architecture.

## 1. Supervisor Configuration

You now have two services to keep alive: `mottzi` (main app) and `mottzi-deployer` (deployment service).

Update `/etc/supervisor/conf.d/mottzi.conf` with the following:

```ini
; /etc/supervisor/conf.d/mottzi.conf

; 1. The Main Application
[program:mottzi]
command=/var/www/mottzi/deploy/Mottzi serve --env development --port 8080
directory=/var/www/mottzi/
user=root
autostart=true
autorestart=true
stdout_logfile=/var/www/mottzi/deploy/Mottzi.log

; 2. The Deployer Service
[program:mottzi-deployer]
command=/var/www/mottzi/deploy/MottziDeployer serve --env development --port 8081
directory=/var/www/mottzi/
user=root
autostart=true
autorestart=true
stdout_logfile=/var/www/mottzi/deploy/Deployer.log
```

After updating the file, run:
```bash
sudo supervisorctl reread
sudo supervisorctl update
```

## 2. Nginx Configuration

You need to route traffic based on the URL. The main app gets general traffic, but the deployment panel and webhooks go to the **Deployer (Port 8081)**.

Update your Nginx configuration (usually in `/etc/nginx/sites-available/default` or similar):

```nginx
# HTTP request handling
# http://mottzi.codes:80/
server {
    server_name mottzi.codes www.mottzi.codes;
    listen 80;
    # REDIRECT mottzi.codes:80/ to mottzi.codes:443/ (permanent)
    return 301 https://$server_name$request_uri;
}

# HTTPS request handling
# https://mottzi.codes:443/
server {
    server_name mottzi.codes www.mottzi.codes;
    listen 443 ssl;
    
    # root
    root /var/www/mottzi/Public/;
    index index.html;

    # SSL - UPDATED PATHS
    ssl_certificate /etc/letsencrypt/live/mottzi.codes/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mottzi.codes/privkey.pem;
    
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # header
    add_header Strict-Transport-Security max-age=15768000;

    # REDIRECT mottzi.codes/ to count.mottzi.codes/ (temporary) - UPDATED URL
    location = / { return 302 https://count.mottzi.codes; }
    
    # 1. Deployment WebSocket (Must go to Deployer on 8081)
    location /deployment/ws/ {
        proxy_pass http://127.0.0.1:8081; # <--- Point to Deployer
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
    }

    # 2. Deployment Panel UI (Must go to Deployer on 8081)
    location /deployment {
        proxy_pass http://127.0.0.1:8081; # <--- Point to Deployer
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 3. GitHub Webhooks (Must go to Deployer on 8081)
    location /pushevent {
        proxy_pass http://127.0.0.1:8081; # <--- Point to Deployer
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 4. Mist WebSocket (Main App on 8080)
    location /mist/ws/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
    }

    # 5. Serve Static Files (Main App)
    location / {
        try_files $uri @proxy;
    }

    # 6. Fallback to Main App (8080)
    location @proxy {
        proxy_pass http://127.0.0.1:8080;
        proxy_pass_header Server;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 3s;
        proxy_read_timeout 10s;
        proxy_intercept_errors on;
        error_page 502 = @redirect;
        error_page 404 = @redirect;
        recursive_error_pages on;
    }

    # 7. Redirect Fallback
    location @redirect { return 302 https://count.mottzi.codes; }
}
```

After updating the file, run:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 3. Database Configuration

Both apps connect to the same SQLite database at `/var/www/mottzi/deploy/Mottzi.db`.
Ensure you enable WAL mode for concurrent access:

```bash
sqlite3 /var/www/mottzi/deploy/Mottzi.db "PRAGMA journal_mode=WAL;"
```
