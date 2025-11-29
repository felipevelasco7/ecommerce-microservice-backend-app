FROM nginx:alpine

# Copiar el archivo HTML al directorio de nginx
COPY index.html /usr/share/nginx/html/

# Configuración de nginx para CORS
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
        \
        # CORS headers \
        add_header Access-Control-Allow-Origin * always; \
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always; \
        add_header Access-Control-Allow-Headers "Content-Type" always; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
