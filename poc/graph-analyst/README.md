# Containerized graph analyst POC

This service embeds Pi through its SDK and exposes a small HTTP API for a read-only analyst agent. The agent uses Gemini 3.6 Flash and calls Graphify through its Streamable HTTP MCP endpoint.

## Run locally

The repository already contains a Graphify graph at `../../graphify-out/graph.json`. The compose stack now starts both Graphify MCP and the Pi agent.

```bash
cd poc/graph-analyst
GEMINI_API_KEY='your-real-key' ANALYST_PORT=8080 docker compose up --build
```

Alternatively, create a local `.env` from `.env.example` and run `docker compose up --build`. The `.env` file is ignored by Docker build context and must not be committed.

Ask a question:

```bash
curl -s http://localhost:8080/ask \
  -H 'content-type: application/json' \
  -d '{"question":"Where is the payment rejection rule implemented?"}' | jq
```

Graphify MCP is internal to the compose network and is not published on the host. `GRAPHIFY_API_KEY` is optional for this private local stack. Set it only when the Graphify service is configured to require one.

Health check:

```bash
curl -s http://localhost:8080/healthz | jq
```

## Required services

`GRAPHIFY_MCP_URL` must point to a Graphify MCP server, for example the shared Kubernetes service from the wider POC. The graph service should expose only read-only tools to this agent.

`GRAPHIFY_API_KEY` is optional. It is not issued by Google and it is not the Gemini API key. Create one only if Graphify is started with its `--api-key` option, then configure the same value in both services. For a private, network-isolated POC, leave it empty.

The Gemini model identifier is `gemini-3.6-flash`. Keep `GEMINI_API_KEY` in a Kubernetes Secret, Docker secret, or external secret manager. Do not bake it into the image or place it in a GitHub Actions log.

## Slack adapter

The future Slack bot can call this service's `POST /ask` endpoint after validating the Slack user, channel, and repository access. The service intentionally does not contain Slack-specific code yet, which keeps the agent independently testable.

## Current limitations

- One configured Graphify MCP endpoint per container.
- No Slack signature validation yet.
- No repository authorization yet.
- No runtime logs, metrics, or production database access.
- No write-capable tools are enabled.
