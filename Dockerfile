# Dockerfile for BrainCell MCP Server (Model Context Protocol)
# Build context: d:\repos (parent directory)
# Copies core modules from ITL.BrainCell repo and installs dependencies
FROM python:3.12-alpine AS builder

WORKDIR /build

RUN apk add --no-cache build-base postgresql-dev

COPY ITL.BrainCell.Mcp/requirements.txt .
RUN pip install --no-cache-dir --target ./python-packages -r requirements.txt

# ========== Runtime Stage ==========
FROM python:3.12-alpine

WORKDIR /app

RUN apk add --no-cache postgresql-client curl

# Copy installed packages from builder
COPY --from=builder /build/python-packages /usr/local/lib/python3.12/site-packages

# Copy BrainCell SDK (shared core library)
COPY ITL.Braincell.SDK/src /sdk/src
COPY ITL.Braincell.SDK/pyproject.toml /sdk/pyproject.toml

# Install SDK in development mode
RUN cd /sdk && pip install --no-cache-dir -e .

# Copy MCP-specific code
COPY ITL.BrainCell.Mcp/src/mcp src/mcp
COPY ITL.BrainCell.Mcp/src/__init__.py src/__init__.py

RUN addgroup braincell && adduser -D -G braincell braincell && \
    chown -R braincell:braincell /app

USER braincell

EXPOSE 9506

HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
    CMD curl -f http://localhost:9506/health || exit 1

CMD ["python", "-m", "src.mcp.server_http"]
