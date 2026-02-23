#!/bin/sh
# Generate API .env from runtime environment variables
cat > /apps/api/.env <<EOF
DB_USERNAME="${DB_USERNAME}"
DB_PASSWORD="${DB_PASSWORD}"
DB_HOST="${DB_HOST}"
DATABASE_URL="postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}/peppermint"
SECRET="${SECRET}"
EOF

# Run prisma migrations
cd /apps/api && npx prisma migrate deploy

# Start PM2 from root (ecosystem.config.js uses relative cwd paths)
cd /
exec pm2-runtime /ecosystem.config.js
