#!/bin/bash
if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    echo "Karmabot is healthy"
    exit 0
else
    echo "Karmabot is not responding"
    exit 1
fi
