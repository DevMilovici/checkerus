FROM gcc:latest

WORKDIR /app

# Install bc for calculations in bash scripts
RUN apt-get update && apt-get install -y bc && rm -rf /var/lib/apt/lists/*

# Copy scripts directory
COPY scripts/ /app/scripts/

# Copy tests directory
COPY tests/ /app/tests/

# Make all .sh files executable
RUN chmod +x /app/scripts/*.sh

CMD ["bash"]