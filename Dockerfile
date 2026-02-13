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

# Create non-root user for security with proper home directory
RUN addgroup --system playwright && adduser --system --ingroup playwright --home /home/playwright playwright

# Change ownership of /app to playwright user
RUN chown -R playwright:playwright /app

# Set up npm directories for the playwright user
RUN mkdir -p /home/playwright/.npm && chown -R playwright:playwright /home/playwright

# Switch to non-root user
USER playwright

# Expose the default MCP port
EXPOSE 8931

# Health check: verify the MCP server is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -q --spider http://localhost:8931/mcp || exit 1

# Set the entrypoint with all required flags, bind to all interfaces for remote access
ENTRYPOINT ["npx", "@playwright/mcp", "--headless", "--browser", "chromium", "--no-sandbox", "--port", "8931", "--host", "0.0.0.0"]
