# ---------- Build ----------
FROM node:24-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci \
    --legacy-peer-deps \
    --ignore-scripts

COPY . .

RUN npx prisma generate

RUN npm run build

# ---------- Production ----------
FROM node:24-alpine AS production

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

# Install production dependencies without executing postinstall.
# Prisma client is generated in the build stage and copied below.
COPY package.json package-lock.json ./

RUN npm ci \
    --omit=dev \
    --legacy-peer-deps \
    --ignore-scripts \
    && npm cache clean --force

# React Router production build
COPY --from=build /app/build ./build

# Generated Prisma client
COPY --from=build /app/generated ./generated

# Runtime server and server-side TS modules
COPY --from=build /app/server.js ./server.js
COPY --from=build /app/app ./app

EXPOSE 3000

CMD ["npm", "run", "start"]