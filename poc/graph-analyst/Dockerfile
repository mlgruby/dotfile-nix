FROM node:24-bookworm-slim

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev --ignore-scripts

COPY src ./src

ENV NODE_ENV=production
EXPOSE 8080
USER node
ENTRYPOINT ["node", "src/server.mjs"]
