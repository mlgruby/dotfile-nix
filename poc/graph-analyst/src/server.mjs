import http from "node:http";
import process from "node:process";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import {
  createAgentSession,
  DefaultResourceLoader,
  defineTool,
  ModelRuntime,
  resolveCliModel,
  SessionManager,
} from "@earendil-works/pi-coding-agent";

const port = Number(process.env.PORT || 8080);
const graphifyUrl = process.env.GRAPHIFY_MCP_URL;
const graphifyApiKey = process.env.GRAPHIFY_API_KEY;
const geminiApiKey = process.env.GEMINI_API_KEY;
const modelId = process.env.PI_MODEL || "gemini-3.6-flash";
const repoRoot = process.env.REPO_ROOT;
const execFileAsync = promisify(execFile);

if (!graphifyUrl) throw new Error("GRAPHIFY_MCP_URL is required");
if (!geminiApiKey) throw new Error("GEMINI_API_KEY is required");

function graphifyClient() {
  const headers = graphifyApiKey
    ? { Authorization: `Bearer ${graphifyApiKey}` }
    : undefined;
  const transport = new StreamableHTTPClientTransport(new URL(graphifyUrl), {
    requestInit: headers ? { headers } : undefined,
  });
  const client = new Client({ name: "graph-analyst-poc", version: "0.1.0" });
  return { client, transport };
}

const queryGraph = defineTool({
  name: "query_company_code",
  label: "Query company code graph",
  description:
    "Search the Graphify knowledge graph for evidence about how the company code works. Use this before answering repository or business-behavior questions.",
  parameters: {
    type: "object",
    properties: {
      question: {
        type: "string",
        description: "The focused question to ask about the codebase",
      },
    },
    required: ["question"],
    additionalProperties: false,
  },
  execute: async (_toolCallId, params, signal) => {
    console.log(`[graph] query: ${params.question}`);
    const { client, transport } = graphifyClient();
    try {
      await client.connect(transport, { signal });
      const availableTools = await client.listTools();
      const queryTool = availableTools.tools.find(
        (tool) => tool.name === "query_graph" || tool.name === "query_graph_tool",
      );
      if (!queryTool) {
        const names = availableTools.tools.map((tool) => tool.name).join(", ");
        throw new Error(`Graphify query tool not found. Available tools: ${names || "none"}`);
      }
      const result = await client.callTool({
        name: queryTool.name,
        arguments: { question: params.question },
      });
      console.log("[graph] query complete");
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(result),
          },
        ],
        details: {},
      };
    } finally {
      await client.close().catch(() => {});
    }
  },
});

const searchRepository = defineTool({
  name: "search_repository_source",
  label: "Search repository source",
  description:
    "Search the checked-out repository for exact configuration and package evidence. Use this for questions about where something is installed, configured, enabled, or declared. A no-match result is not proof that something does not exist.",
  parameters: {
    type: "object",
    properties: {
      query: {
        type: "string",
        description: "A short exact term such as yamlresume, aws sso, or homebrew",
      },
    },
    required: ["query"],
    additionalProperties: false,
  },
  execute: async (_toolCallId, params) => {
    if (!repoRoot) {
      return {
        content: [{ type: "text", text: "Source search is not configured." }],
        details: {},
      };
    }

    const args = [
      "--hidden",
      "--line-number",
      "--no-heading",
      "--fixed-strings",
      "--ignore-case",
      "--glob",
      "!.git/**",
      "--glob",
      "!graphify-out/**",
      "--glob",
      "!.env*",
      "--glob",
      "!*.key",
      "--glob",
      "!*.pem",
      "--glob",
      "!node_modules/**",
      "--max-count",
      "20",
      params.query,
      ".",
    ];

    try {
      const { stdout } = await execFileAsync("rg", args, {
        cwd: repoRoot,
        maxBuffer: 120_000,
      });
      return {
        content: [{ type: "text", text: stdout.trim() || "No source matches found." }],
        details: {},
      };
    } catch (error) {
      if (error?.code === 1) {
        return {
          content: [{ type: "text", text: "No source matches found." }],
          details: {},
        };
      }
      throw error;
    }
  },
});

const systemPrompt = `You answer analysts' questions about company systems using evidence from the code graph.

Rules:
- First classify whether the question is about this repository's code, configuration, dependencies, architecture, or behavior.
- If it is clearly unrelated to this repository, reply with exactly this one sentence and nothing else: "I can only answer questions about this repository. Please ask about its code, configuration, dependencies, or behavior."
- For clearly unrelated questions, do not query the graph and do not provide a repository summary, evidence, confidence score, or follow-up question.
- Query the company code graph before answering repository or business-behavior questions.
- For questions about where a package, setting, profile, tool, or workflow is declared, use the repository source search as well as the graph.
- Explain technical behavior in simple English for a non-technical analyst.
- Distinguish facts found in the graph from reasonable inferences.
- Never invent production state, customer data, configuration values, or business rules.
- Never conclude that something is absent merely because one graph query returned no match. State that the evidence is insufficient unless source search also supports the conclusion.
- Answer the question directly in the first sentence.
- Give only the context needed to understand the answer; normally use one short paragraph or a short list.
- Do not include file paths, line numbers, graph node names, confidence labels, or sections named "Why" or "Evidence" unless the analyst explicitly asks for technical details or sources.
- Do not mention the graph, agent, prompts, or your search process.
- If the graph is insufficient, say so briefly and ask one focused follow-up question.
- You are read-only: do not modify files, execute commands, or suggest that a code change has been made.

Default response style:
<direct answer>

Context: <optional short explanation, only when it helps>`;

const scopePrompt = `Classify the user's question for a repository analyst.

Reply with exactly one word: RELATED or UNRELATED.
RELATED means the question asks about this repository's code, configuration, dependencies, architecture, files, or behavior.
UNRELATED means it is clearly about an outside topic, a different system, general knowledge, or anything this repository cannot answer.
When uncertain, reply RELATED.`;

const unrelatedResponse =
  "I can only answer questions about this repository. Please ask about its code, configuration, dependencies, or behavior.";

function formatAnalystAnswer(text) {
  let answerText = text.trim().replace(/^Answer:\s*/i, "");
  answerText = answerText.split(/\n+\s*(?:Why|Evidence|Confidence|What is unknown):/i)[0].trim();
  return answerText || "I could not find a clear answer in this repository.";
}

async function answer(question) {
  let stage = "model initialization";
  try {
    const modelRuntime = await ModelRuntime.create();
    await modelRuntime.setRuntimeApiKey("google", geminiApiKey);
    const resolvedModel = await resolveCliModel({
      cliModel: `google/${modelId}`,
      modelRuntime,
    });
    if (resolvedModel.error || !resolvedModel.model) {
      throw new Error(resolvedModel.error || `Unknown Google model: ${modelId}`);
    }

    stage = "Question scope classification";
    const scopeLoader = new DefaultResourceLoader({
      cwd: process.cwd(),
      agentDir: process.env.PI_CODING_AGENT_DIR || "/tmp/pi-agent-scope",
      systemPrompt: scopePrompt,
    });
    await scopeLoader.reload();
    const { session: scopeSession } = await createAgentSession({
      model: resolvedModel.model,
      modelRuntime,
      resourceLoader: scopeLoader,
      sessionManager: SessionManager.inMemory(),
      noTools: "builtin",
    });
    let scopeOutput = "";
    scopeSession.subscribe((event) => {
      if (event.type === "message_update" && event.assistantMessageEvent.type === "text_delta") {
        scopeOutput += event.assistantMessageEvent.delta;
      }
    });
    await scopeSession.prompt(question);
    if (/^UNRELATED\b/i.test(scopeOutput.trim())) {
      console.log("[agent] unrelated question rejected");
      return unrelatedResponse;
    }

    stage = "Pi session initialization";
    const resourceLoader = new DefaultResourceLoader({
      cwd: process.cwd(),
      agentDir: process.env.PI_CODING_AGENT_DIR || "/tmp/pi-agent",
      systemPrompt,
    });
    await resourceLoader.reload();

    const { session } = await createAgentSession({
      model: resolvedModel.model,
      modelRuntime,
      resourceLoader,
      sessionManager: SessionManager.inMemory(),
      customTools: [queryGraph, searchRepository],
      noTools: "builtin",
    });

    let output = "";
    session.subscribe((event) => {
      if (event.type === "message_update" && event.assistantMessageEvent.type === "text_delta") {
        output += event.assistantMessageEvent.delta;
      }
    });
    stage = "Gemini answer generation";
    console.log(`[agent] answering: ${question}`);
    await session.prompt(question);
    console.log("[agent] answer complete");
    return formatAnalystAnswer(output || session.getLastAssistantText() || "");
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    throw new Error(`${stage} failed: ${detail}`);
  }
}

function json(res, status, body) {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

const server = http.createServer(async (req, res) => {
  if (req.method === "GET" && req.url === "/healthz") {
    return json(res, 200, { ok: true, model: `google/${modelId}` });
  }

  if (req.method !== "POST" || req.url !== "/ask") {
    return json(res, 404, { error: "Use POST /ask or GET /healthz" });
  }

  try {
    let raw = "";
    for await (const chunk of req) raw += chunk;
    const body = JSON.parse(raw || "{}");
    if (typeof body.question !== "string" || body.question.trim() === "") {
      return json(res, 400, { error: "question must be a non-empty string" });
    }
    const answerText = await answer(body.question.trim());
    return json(res, 200, { answer: answerText, model: `google/${modelId}` });
  } catch (error) {
    console.error(error);
    return json(res, 500, { error: error instanceof Error ? error.message : String(error) });
  }
});

server.listen(port, "0.0.0.0", () => {
  console.log(`graph-analyst-poc listening on :${port}`);
});
