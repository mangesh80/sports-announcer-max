#!/bin/bash

# Cloud Run provides PORT - nginx listens on it
NGINX_PORT=${PORT:-8080}

# Python WebSocket server runs on internal port
PYTHON_PORT=8081

echo "Starting Python WebSocket server on internal port $PYTHON_PORT..."
PORT=$PYTHON_PORT python server.py &
PYTHON_PID=$!

# Brief wait to catch immediate Python startup failures
sleep 2
if ! kill -0 $PYTHON_PID 2>/dev/null; then
    echo "ERROR: Python server failed to start"
    exit 1
fi
echo "Python server started (PID $PYTHON_PID)"

echo "Configuring nginx on port $NGINX_PORT, proxying WebSocket to $PYTHON_PORT..."
sed -i "s/__NGINX_PORT__/$NGINX_PORT/g" /etc/nginx/conf.d/default.conf
sed -i "s/__PYTHON_PORT__/$PYTHON_PORT/g" /etc/nginx/conf.d/default.conf

# Validate nginx config before starting
nginx -t
if [ $? -ne 0 ]; then
    echo "ERROR: nginx config is invalid"
    exit 1
fi

echo "Starting nginx on port $NGINX_PORT..."
nginx -g 'daemon off;'
