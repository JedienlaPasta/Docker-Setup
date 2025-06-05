FROM node:18-alpine AS base
WORKDIR /app

# Deps phase
FROM base AS deps
COPY package.json package-lock.json* ./
RUN npm ci && npm cache clean --force

# Build phase
FROM base AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Production phase
FROM base AS production
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create user and group
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Install ghostscript for PDF support
RUN apk update && apk add --no-cache ghostscript \
    && rm -rf /var/cache/apk/*


COPY --from=build /app/public ./public
COPY --from=build /app/package.json ./package.json

COPY --from=build --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=build --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000

CMD ["node", "server.js"]
