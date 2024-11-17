# Use a base image with GCC pre-installed (for example, debian)
FROM gcc:latest

# Update package list and install bc
RUN apt-get update && apt-get install -y bc

# Optionally, specify a working directory or other setup
WORKDIR /app

# Set the entrypoint or command if needed
CMD ["bash"]
