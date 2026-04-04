#!/usr/bin/env node
import { query } from "@anthropic-ai/claude-code";

const input = JSON.parse(
  await new Promise((resolve) => {
    let data = "";
    process.stdin.on("data", (chunk) => (data += chunk));
    process.stdin.on("end", () => resolve(data));
  })
);

const { tool_name, tool_input } = input;
const filePath = tool_input?.file_path || tool_input?.path || "";

// Only check writes to critical directories
const watchedDirs = ["queries", "composables", "utils", "helpers", "services"];
const isWatchedDir = watchedDirs.some((dir) => filePath.includes(`/${dir}/`));

if (!isWatchedDir || (tool_name !== "Edit" && tool_name !== "Write")) {
  process.exit(0);
}

try {
  const dir = filePath.substring(0, filePath.lastIndexOf("/"));
  const result = await query({
    prompt: `Review this file being created/modified: ${filePath}
Check the directory ${dir} for any existing functions or code that provides similar functionality.
If duplicates exist, respond with ONLY "DUPLICATE: <existing_file>" and explain what to reuse.
If no duplicates, respond with ONLY "OK".`,
    options: { maxTurns: 1 },
  });

  const response = result.at(-1)?.content?.[0]?.text || "";
  if (response.startsWith("DUPLICATE:")) {
    process.stderr.write(
      `⚠️ Potential duplicate detected: ${response}\nConsider reusing existing code instead of creating new.\n`
    );
    process.exit(2);
  }
} catch {
  // If SDK fails, allow the write
}

process.exit(0);
