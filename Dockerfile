# ============================================================
# Stage 1: Builder
# ============================================================
FROM node:22-alpine AS builder

# Instalar pnpm
RUN npm install -g pnpm@10.17.1

WORKDIR /app

# Copiar manifiestos de dependencias primero (cache layer)
COPY package.json pnpm-lock.yaml ./

# Instalar TODAS las dependencias (incluyendo devDependencies para build)
RUN pnpm install --frozen-lockfile

# Copiar el código fuente
COPY . .

# Compilar TypeScript → dist/
RUN pnpm run build

# ============================================================
# Stage 2: Production dependencies only
# ============================================================
FROM node:22-alpine AS deps

RUN npm install -g pnpm@10.17.1

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod

# ============================================================
# Stage 3: Runtime (imagen final mínima)
# ============================================================
FROM node:22-alpine AS runtime

# Seguridad: usuario sin privilegios
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar solo lo necesario para producción
COPY --from=builder /app/dist ./dist
COPY --from=deps    /app/node_modules ./node_modules
COPY --from=builder /app/src/assets ./src/assets
COPY package.json ./

# No ejecutar como root
USER appuser

EXPOSE 3000

# Healthcheck integrado
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/v1/health || exit 1

CMD ["node", "dist/main.js"]
