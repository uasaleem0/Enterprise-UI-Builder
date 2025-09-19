(async () => { require("./hooks/playwright-mcp-adapter.js"); const res = await global.mcpVisualValidate("http://localhost:3003","https://www.athlead.org/",{}); console.log(JSON.stringify(res)); })();
