# Multi-stage build for React todo app
# Stage 1: Build
FROM node:18-alpine AS builder

# FROM node:18-alpine AS builder
FROM public.ecr.aws/docker/library/node:16.18.1-alpine AS builder
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY public/ ./public/
COPY src/ ./src/

# Build the React app with API endpoint
ARG REACT_APP_API_ENDPOINT
ENV REACT_APP_API_ENDPOINT=${REACT_APP_API_ENDPOINT}
RUN npm run build

# Stage 2: Production serve with nginx
FROM nginx:alpine

# FROM nginx:alpine
FROM public.ecr.aws/docker/library/nginx:alpine
# Copy built app from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 3000
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
