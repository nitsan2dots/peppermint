# syntax=docker/dockerfile:1

# ── Base ──────────────────────────────────────────────────
FROM node:22-slim AS base
RUN corepack enable && npm install -g pm2
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# ── Dependencies ──────────────────────────────────────────
FROM base AS deps
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
COPY apps/client/package.json apps/client/
COPY apps/api/package.json apps/api/
COPY apps/api/src/prisma apps/api/src/prisma
COPY packages/config/package.json packages/config/
COPY packages/tsconfig/package.json packages/tsconfig/
RUN yarn install

# ── Builder ───────────────────────────────────────────────
FROM base AS builder
WORKDIR /app
COPY --from=deps /app ./
COPY . .

# Build API (prisma generate + tsc)
RUN cd apps/api && npx prisma generate && npx tsc

# Build Client (next build → standalone output)
RUN cd apps/client && npx next build

# ── Runner ────────────────────────────────────────────────
FROM base AS runner
WORKDIR /

# PM2 ecosystem config
COPY --from=builder /app/ecosystem.config.js .

# 1) Client standalone output
COPY --from=builder /app/apps/client/.next/standalone ./
COPY --from=builder /app/apps/client/.next/static /apps/client/.next/static
COPY --from=builder /app/apps/client/public /apps/client/public
COPY --from=builder /app/apps/client/locales /apps/client/locales

# 2) Full hoisted node_modules (superset — includes API deps)
COPY --from=builder /app/node_modules /node_modules

# 3) API runtime
COPY --from=builder /app/apps/api/dist /apps/api/dist
COPY --from=builder /app/apps/api/node_modules /apps/api/node_modules
COPY --from=builder /app/apps/api/package.json /apps/api/package.json
COPY --from=builder /app/apps/api/src/prisma /apps/api/src/prisma

# 4) Entrypoint — generates .env + runs migrations + starts PM2
COPY entrypoint.sh /entrypoint.sh

EXPOSE 3000 5003
ENTRYPOINT ["/entrypoint.sh"]
