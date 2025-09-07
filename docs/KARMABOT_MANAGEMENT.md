# Karmabot Backend Management Guide

Complete documentation for configuring, deploying, and managing the Karmabot backend on AWS infrastructure.

## 🏗️ Infrastructure Overview

- **Server**: AWS EC2 t3.micro instance
- **Domain**: karmabot.hi5.works
- **Services**: Docker Compose (Karmabot app + MongoDB + InfluxDB)
- **Reverse Proxy**: Nginx with SSL/TLS
- **SSL Certificate**: Let's Encrypt via Certbot

## 📂 File Structure

```
Hi5/prod/
├── karmabot.tf                    # Main Terraform configuration
├── karmabot-subdomain.tf          # Route53 and ACM certificate
├── variables.tf                   # Karmabot variables
├── outputs.tf                     # Terraform outputs
├── templates/
│   └── karmabot.sh.tpl            # EC2 user data script
├── scripts/
│   ├── deploy_karmabot.sh         # Deployment automation
│   └── configure_karmabot_tokens.sh # Token configuration
└── KARMABOT_DEPLOYMENT.md         # Deployment documentation
```

## 🚀 Initial Deployment

### 1. Deploy Infrastructure

```bash
cd /Users/ivan/code/infrastructure/Hi5/prod

# Set required variables
export TF_VAR_karmabot_slack_verification_token="your_verification_token"
export TF_VAR_karmabot_mongodb_uri="mongodb://mongodb:27017/karmabot"

# Deploy
terraform plan -target=aws_instance.karmabot
terraform apply -target=aws_instance.karmabot
```

### 2. Run Deployment Script

```bash
./scripts/deploy_karmabot.sh
```

## 🔧 Server Management

### SSH Access

```bash
# Connect to Karmabot server
ssh ubuntu@52.203.27.35

# Or use the instance ID
aws ec2 describe-instances --filters "Name=tag:Name,Values=karmabot-server"
```

### Service Management

```bash
# Navigate to Karmabot directory
cd /opt/karmabot

# View service status
sudo docker-compose ps

# Start services
sudo docker-compose up -d

# Stop services
sudo docker-compose down

# Restart services
sudo docker-compose restart

# View logs
sudo docker-compose logs -f
sudo docker logs karmabot-app -f
sudo docker logs karmabot-mongodb -f
```

## 🔑 Token Management

### Environment Variables Location

```bash
# Main environment file
/opt/karmabot/.env

# View current tokens
sudo cat /opt/karmabot/.env | grep -E "ACCESS_|BOT_|VERIFICATION"
```

### Add New Workspace Tokens

```bash
# Add tokens for workspace ID (replace WORKSPACE_ID with actual ID)
cd /opt/karmabot
sudo bash -c 'echo "ACCESS_WORKSPACE_ID=xoxp-your-access-token" >> .env'
sudo bash -c 'echo "BOT_WORKSPACE_ID=xoxb-your-bot-token" >> .env'

# Update docker-compose.yml to pass new tokens
sudo nano docker-compose.yml
# Add under karmabot service environment:
#   - ACCESS_WORKSPACE_ID=${ACCESS_WORKSPACE_ID}
#   - BOT_WORKSPACE_ID=${BOT_WORKSPACE_ID}

# Restart services
sudo docker-compose down && sudo docker-compose up -d
```

### Verify Token Loading

```bash
# Check if tokens are loaded in container
sudo docker exec karmabot-app env | grep -E "ACCESS_|BOT_"
```

## 📊 Monitoring and Logs

### Real-time Log Monitoring

```bash
# Monitor all logs
ssh ubuntu@52.203.27.35 "sudo docker logs karmabot-app -f"

# Monitor specific patterns
ssh ubuntu@52.203.27.35 "sudo docker logs karmabot-app -f | grep -E 'POST.*slack_events|ERROR|WARNING'"

# Monitor nginx logs
ssh ubuntu@52.203.27.35 "sudo tail -f /var/log/nginx/access.log"
```

### Health Checks

```bash
# Test endpoint availability
curl -I https://karmabot.hi5.works/

# Test Slack events endpoint
curl -X POST https://karmabot.hi5.works/slack_events/v1/karmabot-v1_events \
  -H "Content-Type: application/json" \
  -d '{"type": "url_verification", "token": "test", "challenge": "test123"}'

# Expected response: {"challenge":"test123"}
```

### Database Access

```bash
# Connect to MongoDB
sudo docker exec -it karmabot-mongodb mongosh karmabot

# View collections
show collections

# Query karma data (example)
db.A09C4RF9HPF.find().limit(5)
```

## 🔄 Application Updates

### Code Updates

```bash
# SSH to server
ssh ubuntu@52.203.27.35
cd /opt/karmabot

# Pull latest code
sudo git pull origin main

# Rebuild and restart
sudo docker-compose build --no-cache karmabot
sudo docker-compose up -d
```

### Dependency Updates

```bash
# Update Python dependencies
sudo docker exec karmabot-app pip install --upgrade -r requirements.txt

# Or rebuild completely
sudo docker-compose build --no-cache karmabot
sudo docker-compose up -d
```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. MongoDB Connection Issues

```bash
# Check MongoDB status
sudo docker logs karmabot-mongodb

# Restart MongoDB
sudo docker-compose restart mongodb

# Fix: Update MongoDB URI in .env
MONGODB_URI=mongodb://mongodb:27017/karmabot
```

#### 2. SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Renew certificate
sudo certbot renew

# Test certificate
curl -I https://karmabot.hi5.works/
```

#### 3. Flask Context Errors

```bash
# Check for context errors in logs
sudo docker logs karmabot-app | grep "ValueError.*Context"

# These are usually non-blocking but indicate async processing issues
# The application continues to work for basic functionality
```

#### 4. OAuth Token Issues

```bash
# Check if tokens are loaded
sudo docker exec karmabot-app env | grep "WORKSPACE_ID"

# Check for token warnings in logs
sudo docker logs karmabot-app | grep "Requested token for workspace"

# Fix: Add missing tokens as shown in Token Management section
```

### Debug Mode

```bash
# Enable debug logging
cd /opt/karmabot
sudo nano .env
# Add: FLASK_ENV=development

# Restart services
sudo docker-compose restart
```

## 🔐 Security Management

### SSL Certificate Renewal

```bash
# Check certificate expiry
sudo certbot certificates

# Automatic renewal (already configured in cron)
sudo certbot renew --dry-run

# Manual renewal if needed
sudo certbot renew
sudo systemctl reload nginx
```

### Firewall Configuration

```bash
# Check current firewall rules
sudo ufw status

# The security group should allow:
# - Port 22 (SSH)
# - Port 80 (HTTP)
# - Port 443 (HTTPS)
# - Port 27017 (MongoDB) - only from localhost
```

## 📈 Performance Monitoring

### Resource Usage

```bash
# Check server resources
ssh ubuntu@52.203.27.35 "top"
ssh ubuntu@52.203.27.35 "df -h"
ssh ubuntu@52.203.27.35 "free -m"

# Check Docker resource usage
ssh ubuntu@52.203.27.35 "sudo docker stats"
```

### Application Metrics

```bash
# Check request patterns
ssh ubuntu@52.203.27.35 "sudo tail -100 /var/log/nginx/access.log | grep slack_events"

# Check error rates
ssh ubuntu@52.203.27.35 "sudo docker logs karmabot-app | grep ERROR | tail -10"
```

## 🔄 Backup and Recovery

### Database Backup

```bash
# Create MongoDB backup
ssh ubuntu@52.203.27.35 "sudo docker exec karmabot-mongodb mongodump --db karmabot --out /tmp/backup"

# Download backup
scp -r ubuntu@52.203.27.35:/tmp/backup ./karmabot-backup-$(date +%Y%m%d)
```

### Configuration Backup

```bash
# Backup configuration files
ssh ubuntu@52.203.27.35 "sudo tar -czf /tmp/karmabot-config.tar.gz -C /opt karmabot"
scp ubuntu@52.203.27.35:/tmp/karmabot-config.tar.gz ./karmabot-config-backup-$(date +%Y%m%d).tar.gz
```

## 🌐 Slack Integration Configuration

### Required Slack App Settings

#### OAuth & Permissions
Required Bot Token Scopes:
- `chat:write`
- `channels:read`
- `groups:read`
- `im:read`
- `mpim:read`
- `users:read`

#### Event Subscriptions
- **Request URL**: `https://karmabot.hi5.works/slack_events/v1/karmabot-v1_events`
- **Bot Events**:
  - `message.channels`
  - `message.groups`
  - `message.im`
  - `message.mpim`
  - `app_mention`

#### Slash Commands
- **Command**: `/karma`
- **Request URL**: `https://karmabot.hi5.works/slack_events/v1/karmabot-v1_commands`

#### Interactive Components
- **Request URL**: `https://karmabot.hi5.works/slack_events/v1/karmabot-v1_interactions`

### Token Configuration

1. **Get tokens from Slack App settings**:
   - Access Token: `xoxp-...` (OAuth & Permissions page)
   - Bot Token: `xoxb-...` (OAuth & Permissions page)
   - Verification Token: (Basic Information page)

2. **Add to server**:
   ```bash
   ssh ubuntu@52.203.27.35
   cd /opt/karmabot
   sudo bash -c 'echo "ACCESS_TEAM_ID=xoxp-your-token" >> .env'
   sudo bash -c 'echo "BOT_TEAM_ID=xoxb-your-token" >> .env'
   ```

3. **Update docker-compose.yml** and restart services

## 📞 Emergency Procedures

### Service Down

```bash
# Quick restart
ssh ubuntu@52.203.27.35 "cd /opt/karmabot && sudo docker-compose restart"

# Full restart
ssh ubuntu@52.203.27.35 "cd /opt/karmabot && sudo docker-compose down && sudo docker-compose up -d"

# Check status
curl -I https://karmabot.hi5.works/
```

### Database Corruption

```bash
# Stop services
sudo docker-compose stop karmabot

# Repair MongoDB
sudo docker exec karmabot-mongodb mongod --repair

# Restart services
sudo docker-compose up -d
```

## 📚 Useful Commands Reference

### Quick Status Check
```bash
curl -s https://karmabot.hi5.works/ && echo "✅ Web accessible" || echo "❌ Web down"
ssh ubuntu@52.203.27.35 "sudo docker-compose ps" | grep Up && echo "✅ Services running" || echo "❌ Services down"
```

### Log Analysis
```bash
# Count recent events
ssh ubuntu@52.203.27.35 "sudo docker logs karmabot-app --since=1h | grep 'slack_events' | wc -l"

# Find errors
ssh ubuntu@52.203.27.35 "sudo docker logs karmabot-app --since=1h | grep -i error"

# Monitor live traffic
ssh ubuntu@52.203.27.35 "sudo tail -f /var/log/nginx/access.log | grep slack"
```

---

## 📝 Notes

- **Server IP**: 52.203.27.35
- **Instance ID**: Check terraform outputs
- **Domain**: karmabot.hi5.works
- **MongoDB Port**: 27017 (internal only)
- **Application Port**: 5000 (internal only)
- **External Ports**: 80, 443 (via nginx)

For additional support, check the logs and refer to the Karmabot GitHub repository at https://github.com/target/karmabot.

