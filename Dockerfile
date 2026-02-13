# Specify the base image (check for the latest tag and specify if preferred)
FROM mcr.microsoft.com/playwright:v1.54.2-noble

# Set working directory (optional)
WORKDIR /app

# Install @playwright/mcp globally
# RUN npm cache clean --force # Try this if you encounter caching issues
RUN npm install -g @playwright/mcp@0.0.32

# Install Chrome browser and dependencies required by Playwright
# Although the base image should include them, explicitly install in case MCP cannot find them
RUN npx playwright install chrome && npx playwright install-deps chrome

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

# Health check: Send a proper JSON-RPC ping request to the MCP server
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f -X POST http://0.0.0.0:8931/mcp \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"ping","id":1}' || exit 1

# Set the entrypoint with all required flags, bind to all interfaces for remote access
# Use --allowed-hosts '*' to accept connections from any host (required for Dokploy/Traefik)
ENTRYPOINT ["npx", "@playwright/mcp", "--headless", "--browser", "chromium", "--no-sandbox", "--port", "8931", "--host", "0.0.0.0", "--allowed-hosts", "*"]
# Set the entrypoint with all required flags, bind to all interfaces for remote access
# Use --allowed-hosts '*' to accept connections from any host (required for Dokploy/Traefik)
ENTRYPOINT ["npx", "@playwright/mcp", "--headless", "--browser", "chromium", "--no-sandbox", "--port", "8931", "--host", "0.0.0.0", "--allowed-hosts", "*"]
