# Analyst code-graph POC

This proof of concept uses Pi as a read-only answer agent and Graphify as the repository knowledge graph. It answers questions about this repository in plain English without giving the agent file-editing or shell tools.

## Run it

From the repository root:

```bash
./scripts/poc/ask-codebase.sh "Where is the Pi coding agent configured?"
./scripts/poc/ask-codebase.sh "How are development tools added to the user environment?"
./scripts/poc/ask-codebase.sh "What happens when this repository's system configuration is rebuilt?"
```

The script uses the checked-in `.pi/mcp.json` configuration. It starts Graphify through `uvx` with its MCP extra, then starts Pi with only the Graphify MCP tools enabled.

The current graph is local and read-only. Refresh it after source changes with:

```bash
graphify update .
```

## What this proves

- Pi can act as the answering harness.
- Graphify can provide structured code and architecture context.
- The agent can be constrained to read-only graph tools.
- A plain-English answer format can be enforced as a reusable skill.

## What this does not prove yet

- Slack identity and channel authorization.
- Kubernetes deployment and persistent graph storage.
- Ten-repository routing.
- Production/runtime data access.

## Next adapter layer

The Slack service should eventually invoke Pi in RPC or SDK mode. It should pass the analyst's question, repository permissions, and environment to Pi, then post the final answer in a thread. The shared Kubernetes deployment can replace the local stdio MCP entry with a Graphify Streamable HTTP endpoint.

Keep the first Slack version read-only. Every answer should include the graph/source commit or deployment version and links to the supporting files.
