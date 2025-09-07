# Karmabot Remote Debugging Guide

This guide explains how to set up and use remote debugging for the Karmabot Flask application running in a Docker container on a remote server.

## 🐛 Debugging Setup

### Prerequisites
- VS Code with Python extension
- Access to the remote server (52.203.27.35)
- Docker and docker-compose on the remote server

### Files Added for Debugging
- `requirements.txt` - Added `debugpy==1.8.0`
- `start-debug.sh` - Debug startup script
- `Dockerfile.debug` - Debug Docker configuration
- `docker-compose.debug.yml` - Debug docker-compose configuration
- `.vscode/launch.json` - VS Code debug configurations
- `setup-debug.sh` - Automated setup script

## 🚀 Quick Start

### 1. Setup Debug Environment
```bash
# Run the setup script to deploy debug files to server
./setup-debug.sh
```

### 2. Start Debug Container
```bash
# SSH to server and start debug container
ssh ubuntu@52.203.27.35 "cd /opt/karmabot && sudo docker-compose -f docker-compose.debug.yml up -d"
```

### 3. Connect Debugger
1. Open VS Code in the karmabot project directory
2. Go to Run and Debug (Ctrl+Shift+D)
3. Select "Python: Remote Attach (Karmabot - Server)"
4. Click the play button or press F5

### 4. Set Breakpoints
- Set breakpoints in your Python code (e.g., in `karmabot/blueprint.py`)
- The debugger will pause execution when breakpoints are hit

## 🔧 Debug Configurations

### Local Debugging (if running locally)
- **Name**: "Python: Remote Attach (Karmabot)"
- **Host**: localhost
- **Port**: 5678

### Remote Debugging (server)
- **Name**: "Python: Remote Attach (Karmabot - Server)"
- **Host**: 52.203.27.35
- **Port**: 5678

## 📝 Debug Features

### Available Debug Features
- **Breakpoints**: Set breakpoints in any Python file
- **Step Through**: Step over, into, and out of functions
- **Variable Inspection**: View variable values in real-time
- **Call Stack**: See the execution call stack
- **Console**: Execute Python code in the debug context

### Path Mappings
The debugger maps local files to remote files:
- **Local**: `${workspaceFolder}` (your local karmabot directory)
- **Remote**: `/app` (container working directory)

## 🛠️ Manual Setup (Alternative)

If the automated setup doesn't work, you can set up manually:

### 1. Copy Files to Server
```bash
scp requirements.txt ubuntu@52.203.27.35:/opt/karmabot/
scp start-debug.sh ubuntu@52.203.27.35:/opt/karmabot/
scp Dockerfile.debug ubuntu@52.203.27.35:/opt/karmabot/
scp docker-compose.debug.yml ubuntu@52.203.27.35:/opt/karmabot/
scp -r karmabot ubuntu@52.203.27.35:/opt/karmabot/
```

### 2. Make Scripts Executable
```bash
ssh ubuntu@52.203.27.35 "cd /opt/karmabot && sudo chmod +x start-debug.sh"
```

### 3. Start Debug Container
```bash
ssh ubuntu@52.203.27.35 "cd /opt/karmabot && sudo docker-compose -f docker-compose.debug.yml up -d"
```

## 🔍 Debugging Tips

### Common Debug Scenarios
1. **Slack Event Processing**: Set breakpoints in `karmabot/blueprint.py` in the `slack_event()` function
2. **Karma Logic**: Debug karma processing in `karmabot/controller/karma.py`
3. **Database Operations**: Debug MongoDB operations in controller files

### Useful Breakpoints
- `karmabot/blueprint.py:95` - "Before regexp" debug message
- `karmabot/blueprint.py:97` - "Event processes" debug message
- `karmabot/controller/karma.py:44` - Karma processing logic

### Testing Debug Connection
```bash
# Send a test request to trigger breakpoints
curl -X POST https://karmabot.hi5.works/slack_events/v1/karmabot-v1_events \
  -H "Content-Type: application/json" \
  -d '{"type": "event_callback", "token": "jKBxIdgFscpNIUHv9ylwN6fZ", "team_id": "T123", "event": {"type": "message", "text": "test++ ", "user": "U123", "channel": "C123"}}'
```

## 🛑 Stopping Debug Mode

### Stop Debug Container
```bash
ssh ubuntu@52.203.27.35 "cd /opt/karmabot && sudo docker-compose -f docker-compose.debug.yml down"
```

### Restart Production Container
```bash
ssh ubuntu@52.203.27.35 "cd /opt/karmabot && sudo docker-compose up -d"
```

## 🐛 Troubleshooting

### Debugger Won't Connect
1. Check if debug container is running: `ssh ubuntu@52.203.27.35 "sudo docker ps | grep debug"`
2. Verify port 5678 is exposed: `ssh ubuntu@52.203.27.35 "sudo docker port karmabot-app-debug"`
3. Check container logs: `ssh ubuntu@52.203.27.35 "sudo docker logs karmabot-app-debug"`

### Breakpoints Not Hit
1. Ensure you're using the correct debug configuration
2. Verify path mappings are correct
3. Check that the code is actually being executed

### Container Won't Start
1. Check Docker logs: `ssh ubuntu@52.203.27.35 "sudo docker logs karmabot-app-debug"`
2. Verify all files were copied correctly
3. Check file permissions: `ssh ubuntu@52.203.27.35 "ls -la /opt/karmabot/start-debug.sh"`

## 📊 Debug vs Production

### Debug Mode Features
- Flask development server (auto-reload)
- Remote debugging enabled
- Debug logging level
- Wait for debugger connection

### Production Mode Features
- Gunicorn WSGI server
- Optimized for performance
- Production logging
- No debugger overhead

## 🔄 Switching Between Modes

### To Debug Mode
```bash
ssh ubuntu@52.203.27.35 "cd /opt/karmabot && sudo docker-compose down && sudo docker-compose -f docker-compose.debug.yml up -d"
```

### To Production Mode
```bash
ssh ubuntu@52.203.27.35 "cd /opt/karmabot && sudo docker-compose -f docker-compose.debug.yml down && sudo docker-compose up -d"
```

---

## 📚 Additional Resources

- [VS Code Python Debugging](https://code.visualstudio.com/docs/python/debugging)
- [debugpy Documentation](https://github.com/microsoft/debugpy)
- [Flask Development Server](https://flask.palletsprojects.com/en/2.0.x/server/)

Happy debugging! 🐛✨
