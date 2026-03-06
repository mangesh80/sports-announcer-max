# Stage 1: Build React frontend
FROM node:20-slim AS frontend-build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Runtime - nginx + Python
FROM python:3.11-slim

# Install nginx
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir

# Copy Python WebSocket server
COPY server.py .

# Copy built React app to nginx web root
COPY --from=frontend-build /app/dist /var/www/html
RUN chmod -R 755 /var/www/html

# Copy nginx config and startup script
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY start.sh .
RUN chmod +x start.sh

# Remove default nginx site
RUN rm -f /etc/nginx/sites-enabled/default

CMD ["./start.sh"]
