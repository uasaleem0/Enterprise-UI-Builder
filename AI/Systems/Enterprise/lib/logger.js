#!/usr/bin/env node

/**
 * Simple JSONL logger
 */

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

async function appendEvent(projectPath, event) {
  try {
    const logDir = path.join(projectPath, 'logs');
    await fsp.mkdir(logDir, { recursive: true });
    const line = JSON.stringify({ ts: new Date().toISOString(), ...event }) + '\n';
    fs.appendFileSync(path.join(logDir, 'run.jsonl'), line, 'utf8');
  } catch {}
}

module.exports = { appendEvent };

