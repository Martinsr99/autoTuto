FROM node:20-alpine

# Install dependencies for multi-arch support
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files
COPY package.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm install

# Copy source files
COPY *.ts ./

# Create output directories
RUN mkdir -p /output /temp /templates

# Keep container running
CMD ["tail", "-f", "/dev/null"]
