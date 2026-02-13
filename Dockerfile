# Specify the base image (check for the latest tag and specify if preferred)
FROM mcr.microsoft.com/playwright:v1.54.2-noble

# Set working directory (optional)
WORKDIR /app

# Install @playwright/mcp globally
# RUN npm cache clean --force # Try this if you encounter caching issues
RUN npm install -g @playwright/mcp@0.0.32

# Install playwright package first to avoid installation warnings
RUN npm install -g @playwright/test

# Install system dependencies for Chromium as root (requires sudo)
RUN npx playwright install-deps chromium

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user for security with proper home directory
RUN addgroup --system playwright && adduser --system --ingroup playwright --home /home/playwright playwright

# Change ownership of /app to playwright user
RUN chown -R playwright:playwright /app

# Set up npm directories for the playwright user
RUN mkdir -p /home/playwright/.npm && chown -R playwright:playwright /home/playwright

# Switch to non-root user
USER playwright

# Install Chromium browser as the playwright user
# This ensures the browser is accessible to the user running the MCP server
RUN npx playwright install chromium

# Expose the default MCP port
EXPOSE 8931

# Set the entrypoint with all required flags, bind to all interfaces for remote access
# Use --allowed-hosts '*' to accept connections from any host (required for Dokploy/Traefik)
ENTRYPOINT ["npx", "@playwright/mcp", "--headless", "--browser", "chromium", "--no-sandbox", "--port", "8931", "--host", "0.0.0.0", "--allowed-hosts", "*", "--vision"]
