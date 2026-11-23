const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const parse = require('luaparse').parse;
const root = path.resolve(__dirname, '..');
const addon = path.join(root, 'SatchelSense');
const toc = fs.readFileSync(path.join(addon, 'SatchelSense.toc'), 'utf8');
assert.match(toc, /## Interface: 16001/);
assert.match(toc, /## Dependencies: PocketBuffs/);
const bridgeDir = path.join(root, 'PocketBuffs');
const bridgeToc = fs.readFileSync(path.join(bridgeDir, 'PocketBuffs.toc'), 'utf8');
assert.match(bridgeToc, /## SavedVariablesPerCharacter: PocketBuffsDB/);
assert.deepEqual(bridgeToc.split(/\r?\n/).filter(x => x && !x.startsWith('#')), ['Bridge.lua']);
const files = toc.split(/\r?\n/).filter(x => x && !x.startsWith('#'));
for (const file of files) assert.ok(fs.existsSync(path.join(addon, file)), `Missing ${file}`);
for (const [name, size] of [['AddonIcon', 64], ['PouchArt', 256]]) {
  const bytes = fs.readFileSync(path.join(addon, 'Media', name + '.tga'));
  assert.equal(bytes[2], 2);
  assert.equal(bytes[16], 32);
  assert.equal(bytes[17], 0x28);
  assert.equal(bytes.readUInt16LE(12), size);
  assert.equal(bytes.readUInt16LE(14), size);
  assert.equal(bytes.length, 18 + size * size * 4);
}
const avatar = fs.readFileSync(path.join(root, 'Branding', 'SatchelSense-400.png'));
assert.equal(avatar.readUInt32BE(16), 400);
assert.equal(avatar.readUInt32BE(20), 400);
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
function run(source, name) {
  if (lauxlib.luaL_loadbuffer(L, to_luastring(source), null, to_luastring(name)) !== lua.LUA_OK ||
      lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) throw Error(`${name}: ${to_jsstring(lua.lua_tostring(L, -1))}`);
}
run(fs.readFileSync(path.join(__dirname, 'wow-mock.lua'), 'utf8'), 'WoW mock');
run(fs.readFileSync(path.join(bridgeDir, 'Bridge.lua'), 'utf8'), 'Legacy settings loader');
for (const file of files.filter(x => x.endsWith('.lua'))) {
  const source = fs.readFileSync(path.join(addon, file), 'utf8');
  parse(source, { luaVersion: '5.1' });
  run(`assert(load(${JSON.stringify(source)}, ${JSON.stringify(file)}))('SatchelSense', TEST_NS)`, file);
}
run(fs.readFileSync(path.join(__dirname, 'behavior.lua'), 'utf8'), 'Behavior');
run(fs.readFileSync(path.join(__dirname, 'editing-cooldowns.lua'), 'utf8'), 'Editing, item bindings and cooldowns');
run(fs.readFileSync(path.join(__dirname, 'grid-editing.lua'), 'utf8'), 'Direct grid editing');
run(fs.readFileSync(path.join(__dirname, 'drag-release-slots.lua'), 'utf8'), 'Drag release recovery and persistent grid slots');
run(fs.readFileSync(path.join(__dirname, 'rebrand-migration.lua'), 'utf8'), 'Rebrand compatibility');
console.log('PASS: Lua 5.1 syntax, packaging, discovery, layout, combat stability, settings, recovery and bindings.');
