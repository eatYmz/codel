# STEP 1: Build the frontend
FROM node:21-slim as fe-build

ENV NODE_ENV=production
ENV VITE_API_URL=localhost:3000

WORKDIR /frontend

COPY ./backend/graph/schema.graphqls ../backend/graph/

COPY frontend/ .

RUN yarn install --frozen-lockfile --production=false
RUN ls -la /frontend
RUN yarn build

# STEP 2: Build the backend
FROM golang:1.22-alpine as be-build
ENV CGO_ENABLED=1
RUN apk add --no-cache gcc musl-dev

WORKDIR /backend

COPY backend/ .

RUN go mod download

RUN go build -ldflags='-extldflags "-static"' -o /app

# STEP 3: Build the final image
FROM alpine:3.14

COPY --from=be-build /app /app
COPY --from=fe-build /frontend/dist /fe

# Install sqlite3
RUN apk add --no-cache sqlite

# Set environment variables
ENV OPEN_AI_KEY=your_open_ai_key
ENV OPEN_AI_MODEL=gpt-4-0125-preview
ENV OLLAMA_MODEL=llama2

# Expose the necessary port
EXPOSE 3000

# Set up volume binding
VOLUME /var/run/docker.sock:/var/run/docker.sock

# Final command to run the application
CMD ["sh", "-c", "docker run -p 3000:8080 -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/semanser/codel:latest"]
