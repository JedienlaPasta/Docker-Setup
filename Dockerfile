# Etapa base
FROM node:18-alpine AS base # <--- Changed here
WORKDIR /app

# Etapa de dependencias
FROM base AS deps
# Instead of apt-get, use apk for Alpine
RUN apk update && apk add --no-cache ghostscript # <--- Changed here
COPY package.json package-lock.json* ./
RUN npm install --include=optional

# Etapa de build
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Etapa final de producción
FROM base AS production
ENV NODE_ENV=production

# 👇 Instalar Ghostscript en la imagen final
# Instead of apt-get, use apk for Alpine
RUN apk update && apk add --no-cache ghostscript # <--- Changed here

COPY --from=build /app/public ./public
COPY --from=build /app/.next ./.next
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json

EXPOSE 3000
CMD ["npm", "start"]
