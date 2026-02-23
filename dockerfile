# syntax=docker/dockerfile:1
FROM pepperlabs/peppermint:latest

# Fix: whitelist registration and password-reset endpoints in auth middleware
RUN sed -i 's|if (request.url === "/api/v1/ticket/public/create" &&|if (request.url === "/api/v1/auth/user/register/external" \&\& request.method === "POST") {\n            return true;\n        }\n        if (request.url === "/api/v1/auth/password-reset" \&\& request.method === "POST") {\n            return true;\n        }\n        if (request.url === "/api/v1/ticket/public/create" \&\&|' /apps/api/dist/main.js
