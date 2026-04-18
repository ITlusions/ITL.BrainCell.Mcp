# Dockerfile for BrainCell MCP Server (Model Context Protocol)
# Build context must be D:\repos\ (parent of all ITL.BrainCell* repos)
FROM python:3.12-alpine AS builder

WORKDIR /build

RUN apk add --no-cache build-base postgresql-dev

COPY ITL.BrainCell.Mcp/requirements.txt .
RUN pip install --no-cache-dir --target ./python-packages -r requirements.txt

# ========== Runtime Stage ==========
FROM python:3.12-alpine

WORKDIR /app

RUN apk add --no-cache postgresql-client curl

COPY --from=builder /build/python-packages /usr/local/lib/python3.12/site-packages

# Copy shared core from ITL.BrainCell
COPY ITL.BrainCell/src/core src/core
COPY ITL.BrainCell/src/cells src/cells
COPY ITL.BrainCell/src/services src/services
COPY ITL.BrainCell/src/__init__.py src/__init__.py

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
