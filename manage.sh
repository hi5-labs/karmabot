#!/bin/bash
cd /opt/karmabot

case "$1" in
    start)
        docker-compose up -d
        ;;
    stop)
        docker-compose down
        ;;
    restart)
        docker-compose restart
        ;;
    logs)
        docker-compose logs -f
        ;;
    status)
        docker-compose ps
        ;;
    update)
        git pull
        docker-compose build
        docker-compose up -d
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status|update}"
        exit 1
        ;;
esac
