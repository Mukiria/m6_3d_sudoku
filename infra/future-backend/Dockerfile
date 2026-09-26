# Placeholder shape for a future cloud-sync API — see README.md in this
# directory. Nothing today builds or deploys this.

FROM node:20-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .

FROM node:20-slim
RUN groupadd -r app && useradd -r -g app app
WORKDIR /app
COPY --from=build /app /app
USER app
ENV PORT=8080
EXPOSE 8080
# Cloud Run / k8s liveness probes hit this
HEALTHCHECK --interval=30s --timeout=3s CMD node -e "require('http').get('http://localhost:8080/healthz', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"
CMD ["node", "server.js"]
