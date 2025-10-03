FROM jrottenberg/ffmpeg:6-alpine
LABEL maintainer="Video Pipeline"

# Install bash and other utilities
RUN apk add --no-cache bash curl

# Create necessary directories
RUN mkdir -p /templates /output /temp /scripts

# Copy processing scripts
COPY process-video.sh /scripts/
RUN chmod +x /scripts/process-video.sh

WORKDIR /temp

# Keep container running
CMD ["tail", "-f", "/dev/null"]
