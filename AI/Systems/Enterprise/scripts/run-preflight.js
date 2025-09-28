#!/usr/bin/env node
(async () => {
  try {
    const { runPreflight } = require('../lib/preflight');
    const r = await runPreflight();
    console.log(JSON.stringify(r, null, 2));
  } catch (e) {
    console.error(e && e.message ? e.message : String(e));
    process.exit(1);
  }
})();

