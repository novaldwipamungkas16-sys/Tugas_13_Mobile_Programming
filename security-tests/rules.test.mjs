import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, addDoc, serverTimestamp, Timestamp, setLogLevel } from 'firebase/firestore';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
const projectId = 'demo-lkm-mahasiswa-t13';
if (process.env.GCLOUD_PROJECT !== projectId || process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') throw Error('Run through explicit demo emulators:exec only');
setLogLevel('error');
const rules = readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');
const env = await initializeTestEnvironment({ projectId, firestore: { host: '127.0.0.1', port: 8080, rules } });
const member = (uid, extra = {}) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'password' }, ...extra }).firestore();
const a = member('user-a'), b = member('user-b'), admin = member('admin', { admin: true });
const guest = env.authenticatedContext('guest', { firebase: { sign_in_provider: 'anonymous' } }).firestore();
const unauth = env.unauthenticatedContext().firestore();
const ref = (db, id) => doc(db, 'mahasiswa', id);
const data = (ownerUid = '') => ({ ownerUid, nim: '12345', nama: 'Dummy Student', prodi: 'Teknik Informatika', angkatan: 2024, createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
const results = [];
async function test(id, expected, action) {
  const start = Date.now(); let observed = 'ALLOW', error;
  try { await action(); } catch (e) { observed = e.code === 'permission-denied' ? 'DENY' : 'ERROR'; error = { code: e.code || e.name, message: e.message }; }
  const passed = observed === expected;
  results.push({ id, expected, observed, passed, durationMs: Date.now() - start, ...(error ? { error } : {}) });
  console.log(`${passed ? 'PASS' : 'FAIL'} ${id} expected=${expected} observed=${observed}${error ? ' code=' + error.code : ''}`);
}
try {
  await env.clearFirestore();
  await test('T02 guest get', 'DENY', () => getDoc(ref(guest, 'user-a')));
  await test('T03 guest create', 'DENY', () => setDoc(ref(guest, 'guest'), data('guest')));
  await test('T04 user A create; admin claim absent', 'ALLOW', async () => { await setDoc(ref(a, 'user-a'), data('user-a')); assert.equal((await getDoc(ref(a, 'user-a'))).data().ownerUid, 'user-a'); });
  await test('SETUP user B create', 'ALLOW', () => setDoc(ref(b, 'user-b'), data('user-b')));
  await test('T03 guest update existing', 'DENY', () => updateDoc(ref(guest, 'user-a'), { nama: 'attack' }));
  await test('T05 user A get own', 'ALLOW', async () => assert.equal((await getDoc(ref(a, 'user-a'))).data().nim, '12345'));
  await test('T06 user A get B', 'DENY', () => getDoc(ref(a, 'user-b')));
  await test('T07 user A list', 'DENY', () => getDocs(collection(a, 'mahasiswa')));
  for (const [field, value] of Object.entries({ nim: '99999', ownerUid: 'user-b', createdAt: Timestamp.fromMillis(0) })) await test('T08 change ' + field, 'DENY', () => updateDoc(ref(a, 'user-a'), { [field]: value }));
  await test('T09 own delete', 'DENY', () => deleteDoc(ref(a, 'user-a')));
  await test('T10 admin list', 'ALLOW', async () => assert.equal((await getDocs(collection(admin, 'mahasiswa'))).size, 2));
  let archive;
  await test('T11 admin auto-ID archive create readback', 'ALLOW', async () => { archive = await addDoc(collection(admin, 'mahasiswa'), data()); assert.equal((await getDoc(archive)).data().ownerUid, ''); });
  await test('T11 admin edit readback', 'ALLOW', async () => { await updateDoc(archive, { nim: '54321', nama: 'Archive Edited', updatedAt: serverTimestamp() }); assert.equal((await getDoc(archive)).data().nim, '54321'); });
  await test('T11 admin delete readback', 'ALLOW', async () => { await deleteDoc(archive); assert.equal((await getDoc(archive)).exists(), false); });
  await test('T12 role field escalation', 'DENY', () => updateDoc(ref(a, 'user-a'), { role: 'admin' }));
  await test('L6 admin field escalation', 'DENY', () => updateDoc(ref(a, 'user-a'), { admin: true }));
  await test('L5 edit name prodi readback', 'ALLOW', async () => { await updateDoc(ref(a, 'user-a'), { nama: 'Changed', prodi: 'Sistem Informasi', updatedAt: serverTimestamp() }); const d = (await getDoc(ref(a, 'user-a'))).data(); assert.equal(d.nama, 'Changed'); assert.equal(d.prodi, 'Sistem Informasi'); assert.equal(d.nim, '12345'); });
  await test('own missing document get', 'ALLOW', async () => assert.equal((await getDoc(ref(member('new-user'), 'new-user'))).exists(), false));
  await test('create wrong document ID', 'DENY', () => setDoc(ref(a, 'someone-else'), data('user-a')));
  await test('create wrong ownerUid', 'DENY', () => setDoc(ref(member('new-user'), 'new-user'), data('user-a')));
  await test('cross-user update', 'DENY', () => updateDoc(ref(a, 'user-b'), { nama: 'attack' }));
  await test('unauthenticated get', 'DENY', () => getDoc(ref(unauth, 'user-a')));
  await test('unauthenticated create', 'DENY', () => setDoc(ref(unauth, 'x'), data()));
  await test('anonymous with admin claim list', 'DENY', () => getDocs(collection(env.authenticatedContext('guest-admin', { admin: true, firebase: { sign_in_provider: 'anonymous' } }).firestore(), 'mahasiswa')));
  await test('string admin claim list', 'DENY', () => getDocs(collection(member('bad-admin', { admin: 'true' }), 'mahasiswa')));
  await test('admin false list', 'DENY', () => getDocs(collection(member('false-admin', { admin: false }), 'mahasiswa')));
  await test('other collection admin write', 'DENY', () => setDoc(doc(admin, 'roles', 'admin'), { admin: true }));
  await test('other collection admin read', 'DENY', () => getDoc(doc(admin, 'roles', 'admin')));
  await test('nested collection admin write', 'DENY', () => setDoc(doc(admin, 'mahasiswa/user-a/private/data'), { x: 1 }));
  let sequence = 0;
  for (const [field, values] of Object.entries({ ownerUid: [['', true], ['x'.repeat(128), true], ['x'.repeat(129), false], [1, false]], nim: [['1234', false], ['12345', true], ['1'.repeat(20), true], ['1'.repeat(21), false], [12345, false]], nama: [['', false], ['a', true], ['a'.repeat(100), true], ['a'.repeat(101), false], [5, false]], prodi: [['', false], ['a', true], ['a'.repeat(80), true], ['a'.repeat(81), false], [5, false]], angkatan: [[1999, false], [2000, true], [2100, true], [2101, false], [2024.5, false], ['2024', false]], createdAt: [['bad', false], [null, false]], updatedAt: [['bad', false], [null, false]] })) {
    for (const [value, valid] of values) await test(`BOUNDARY ${field} ${JSON.stringify(value)}`, valid ? 'ALLOW' : 'DENY', async () => { const r = ref(admin, 'boundary-' + sequence++); await setDoc(r, { ...data(), [field]: value }); assert.equal((await getDoc(r)).exists(), true); });
  }
  for (const field of Object.keys(data())) await test('missing field ' + field, 'DENY', () => { const d = data(); delete d[field]; return setDoc(ref(admin, 'missing-' + field), d); });
  await test('admin invalid update', 'DENY', () => updateDoc(ref(admin, 'user-a'), { angkatan: 1999 }));
  await test('admin extra field', 'DENY', () => setDoc(ref(admin, 'extra'), { ...data(), role: 'admin' }));
} finally {
  await env.cleanup();
  mkdirSync(new URL('../documentation/security-evidence/', import.meta.url), { recursive: true });
  const report = { projectId, backend: 'real Firestore Emulator; Firebase client SDK (not Admin SDK)', rulesSha256: createHash('sha256').update(rules).digest('hex'), generatedAt: new Date().toISOString(), total: results.length, passed: results.filter(r => r.passed).length, failed: results.filter(r => !r.passed).length, results };
  writeFileSync(new URL('../documentation/security-evidence/rules-results.json', import.meta.url), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ total: report.total, passed: report.passed, failed: report.failed }));
  if (report.failed) process.exitCode = 1;
}
