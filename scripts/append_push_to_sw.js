/**
 * Appends apps/player/web/push_handler.js to the built Flutter service worker
 * so push notifications work when the app is closed.
 * Run from repo root after: cd apps/player && flutter build web
 *
 * Usage: node scripts/append_push_to_sw.js
 */

const fs = require('fs');
const path = require('path');

const buildSw = path.join(__dirname, '../apps/player/build/web/flutter_service_worker.js');
const pushHandler = path.join(__dirname, '../apps/player/web/push_handler.js');
const outPath = buildSw;

if (!fs.existsSync(buildSw)) {
  console.error('Run "flutter build web" in apps/player first. Missing:', buildSw);
  process.exit(1);
}
if (!fs.existsSync(pushHandler)) {
  console.error('Missing push handler:', pushHandler);
  process.exit(1);
}

const swContent = fs.readFileSync(buildSw, 'utf8');
const pushContent = fs.readFileSync(pushHandler, 'utf8');
const combined = swContent.trimEnd() + '\n\n// Club Blackout push handler\n' + pushContent + '\n';
fs.writeFileSync(outPath, combined, 'utf8');
console.log('Appended push handler to flutter_service_worker.js');
console.log('Deploy build/web for push to work when app is closed.');
