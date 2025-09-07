# Karmabot Deployment Guide

This document describes how to deploy and configure Karmabot on your existing infrastructure.

## Overview

Karmabot is a Slack bot that implements a karma/reputation system. Users can give karma to things, users, channels, and groups by adding `++` or `--` to the end of a subject.

## Architecture

The deployment includes:
- **EC2 Instance**: t3.micro Ubuntu 24.04 server
- **MongoDB**: Database for storing karma operations
- **Docker**: Containerized application deployment
- **Nginx**: Reverse proxy for web interface
- **Route53**: DNS management

## Prerequisites

1. **Slack App Setup**: You need to create a Slack app at https://api.slack.com/apps
2. **Domain**: The deployment uses `karmabot.hi5.works` as the domain
3. **AWS Access**: Ensure you have the necessary AWS permissions

## Slack App Configuration

### 1. Create Slack App

1. Go to https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. Name: `Karmabot`
4. Select your workspace

### 2. Configure Slash Commands

1. Go to "Slash Commands" in the left sidebar
2. Click "Create New Command"
3. Configure `/karma` command:
   - Command: `karma`
   - Request URL: `https://karmabot.hi5.works/slack_events`
   - Short Description: `Karma operations`
   - **Important**: Check "Escape channels, users, and links"

4. Configure `/badge` command:
   - Command: `badge`
   - Request URL: `https://karmabot.hi5.works/slack_events`
   - Short Description: `Badge operations`
   - **Important**: Check "Escape channels, users, and links"

### 3. Configure Event Subscriptions

1. Go to "Event Subscriptions" in the left sidebar
2. Enable Events
3. Request URL: `https://karmabot.hi5.works/slack_events`
4. Subscribe to Bot Events:
   - `app_mention`
   - `message.channels`
   - `message.groups`

### 4. Configure OAuth & Permissions

1. Go to "OAuth & Permissions" in the left sidebar
2. Add the following Bot Token Scopes:
   - `bot`
   - `commands`
   - `channels:write`
   - `chat:write:bot`
   - `im:write`
   - `usergroups:read`

3. Install the app to your workspace
4. Copy the following tokens:
   - **Bot User OAuth Token** (starts with `xoxb-`)
   - **Verification Token** (from Basic Information)

### 5. Invite Bot to Channels

Invite the Karmabot to channels where you want to track karma:
```
/invite @Karmabot
```

## Deployment

### 1. Set Environment Variables

Before deploying, you need to set the Slack verification token. You can do this by:

1. **Option A**: Set in `prod.auto.tfvars`:
   ```hcl
   karmabot_slack_verification_token = "your-verification-token-here"
   ```

2. **Option B**: Use AWS Systems Manager Parameter Store:
   ```bash
   aws ssm put-parameter \
     --name "/karmabot/slack_verification_token" \
     --value "your-verification-token-here" \
     --type "SecureString"
   ```

### 2. Deploy Infrastructure

```bash
cd Hi5/prod
terraform plan
terraform apply
```

### 3. Configure Slack Tokens

After deployment, you need to configure the Slack access tokens. You have two options:

#### Option A: Environment Variables (Simple)

SSH into the Karmabot instance and set environment variables:

```bash
ssh ubuntu@karmabot.hi5.works

# Edit the environment file
sudo nano /opt/karmabot/.env

# Add your Slack tokens:
ACCESS_T1234567890=xoxa-your-oauth-access-token
BOT_T1234567890=xoxb-your-bot-token

# Restart Karmabot
sudo /opt/karmabot/manage.sh restart
```

#### Option B: Hashicorp Vault (Advanced)

If you want to use Vault for token management:

1. Set up Vault
2. Store tokens in Vault:
   ```bash
   vault write secret/secrets/access_T1234567890.txt value=xoxa-your-oauth-access-token
   vault write secret/secrets/bot_T1234567890.txt value=xoxb-your-bot-token
   ```
3. Configure Vault environment variables in `/opt/karmabot/.env`

### 4. Verify Deployment

1. Check if Karmabot is running:
   ```bash
   sudo /opt/karmabot/manage.sh status
   ```

2. Check logs:
   ```bash
   sudo /opt/karmabot/manage.sh logs
   ```

3. Test the web interface:
   ```bash
   curl http://karmabot.hi5.works
   ```

## Usage

### Basic Karma Operations

- Give karma: `thing++` or `@user++`
- Remove karma: `thing--` or `@user--`
- Check karma: `/karma thing` or `/karma @user`

### Advanced Commands

- `/karma top` - Show top karma recipients
- `/karma bottom` - Show bottom karma recipients
- `/karma stats` - Show karma statistics
- `/badge list` - List available badges
- `/badge give @user badge_name` - Give a badge to a user

### Examples

```
coffee++          # Give karma to "coffee"
@john++           # Give karma to user John
python--          # Remove karma from "python"
/karma coffee     # Check karma for "coffee"
/karma top        # Show top karma recipients
```

## Management

### Service Management

```bash
# Start Karmabot
sudo /opt/karmabot/manage.sh start

# Stop Karmabot
sudo /opt/karmabot/manage.sh stop

# Restart Karmabot
sudo /opt/karmabot/manage.sh restart

# View logs
sudo /opt/karmabot/manage.sh logs

# Check status
sudo /opt/karmabot/manage.sh status

# Update Karmabot
sudo /opt/karmabot/manage.sh update
```

### Database Management

MongoDB data is persisted in a Docker volume. To access the database:

```bash
# Connect to MongoDB
docker exec -it karmabot-mongodb mongosh -u karmabot -p karmabot123

# Backup database
docker exec karmabot-mongodb mongodump --out /data/backup

# Restore database
docker exec karmabot-mongodb mongorestore /data/backup
```

### SSL Certificate

To enable HTTPS:

```bash
# Install SSL certificate
sudo certbot --nginx -d karmabot.hi5.works --non-interactive --agree-tos --email admin@hi5.works

# Auto-renewal is already configured
```

## Monitoring

### Health Checks

The deployment includes a health check script:

```bash
sudo /opt/karmabot/health-check.sh
```

### Logs

- Application logs: `sudo /opt/karmabot/manage.sh logs`
- System logs: `sudo journalctl -u karmabot`
- Nginx logs: `sudo tail -f /var/log/nginx/access.log`

### Metrics

Karmabot can send metrics to InfluxDB. To configure:

1. Set up Telegraf or InfluxDB
2. Configure the metrics endpoint in the environment variables

## Troubleshooting

### Common Issues

1. **Karmabot not responding to Slack events**
   - Check if the verification token is correct
   - Verify the Slack app is properly configured
   - Check the logs: `sudo /opt/karmabot/manage.sh logs`

2. **MongoDB connection issues**
   - Check if MongoDB container is running: `docker ps`
   - Verify MongoDB credentials in the environment file
   - Check MongoDB logs: `docker logs karmabot-mongodb`

3. **Nginx issues**
   - Check Nginx configuration: `sudo nginx -t`
   - Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`

4. **SSL certificate issues**
   - Ensure the domain is pointing to the correct IP
   - Check if port 80 is accessible for certificate validation

### Debug Mode

To enable debug logging, add to `/opt/karmabot/.env`:
```
DEBUG=true
```

Then restart Karmabot:
```bash
sudo /opt/karmabot/manage.sh restart
```

## Security Considerations

1. **Firewall**: Only necessary ports are open (22, 80, 443, 27017)
2. **MongoDB**: Access is restricted to the local network
3. **SSL**: HTTPS is recommended for production use
4. **Tokens**: Slack tokens should be stored securely (use Vault or Parameter Store)
5. **Updates**: Regularly update the system and Karmabot application

## Backup and Recovery

### Backup Strategy

1. **Database**: MongoDB data is in a Docker volume
2. **Configuration**: Environment file and Docker Compose configuration
3. **Code**: Karmabot code is cloned from GitHub

### Backup Commands

```bash
# Backup MongoDB
docker exec karmabot-mongodb mongodump --out /data/backup

# Backup configuration
sudo cp /opt/karmabot/.env /opt/karmabot/.env.backup

# Backup Docker volumes
docker run --rm -v karmabot_mongodb_data:/data -v $(pwd):/backup alpine tar czf /backup/mongodb_backup.tar.gz -C /data .
```

## Cost Optimization

- **Instance Type**: Using t3.micro (cheapest option)
- **Storage**: EBS volumes are minimal
- **Data Transfer**: Minimal for Slack webhooks
- **Monitoring**: Basic health checks included

## Support

For issues with Karmabot itself, check the [official repository](https://github.com/target/karmabot).

For infrastructure issues, check the Terraform logs and AWS CloudWatch.
