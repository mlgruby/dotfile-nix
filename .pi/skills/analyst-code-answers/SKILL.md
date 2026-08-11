---
name: analyst-code-answers
description: Answer repository questions from the Graphify knowledge graph in plain English.
---

# Analyst code answers

Use this skill for questions about how this repository works, where a behavior is implemented, or why a configuration produces a result.

## Required workflow

1. Query the `graphify-local` MCP server before inspecting broad source files.
2. Use `query_graph` for open questions, `get_node` for a named concept, and `shortest_path` for relationships between two concepts.
3. Follow the returned source paths and line references when the graph result is not enough.
4. Answer in simple English for a non-technical reader.
5. Separate observed facts from inferences.
6. Include the repository path, relevant files/lines, and the graph/source version when available.
7. If the graph does not contain enough evidence, say so and ask a focused follow-up question.

## Answer format

Use this compact structure:

```text
Answer:
<plain-English explanation>

Why:
<the relevant rule or flow>

Evidence:
- <file and line or graph concept>

Confidence: High | Medium | Low
```

Do not invent business rules, runtime state, or production values that are not present in the graph or source. Avoid dumping code unless the user explicitly asks for it.
