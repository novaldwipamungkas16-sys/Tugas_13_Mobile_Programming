import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, signInWithCustomToken, getIdTokenResult } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator, collection, getDocs, terminate } from 'firebase/firestore';
const require = createRequire(new URL('../admin-tools/package.json', import.meta.url));
const { initializeApp: initializeAdminApp, applicationDefault, deleteApp: deleteAdminApp, getApp } = require('firebase-admin/app');
const { getAuth: getAdminAuth } = require('firebase-admin/auth');
const projectId = 'demo-lkm-mahasiswa-t13';
if (process.env.GCLOUD_PROJECT !== projectId || process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099' || process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') throw Error('Explicit local demo emulators required');
initializeAdminApp({ projectId });
const uid = 'claim-script-user';
try { await getAdminAuth().deleteUser(uid); } catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
await getAdminAuth().createUser({ uid });
await getAdminAuth().setCustomUserClaims(uid, { course: 't13', retainedFlag: true });
const app = initializeApp({ projectId, apiKey: 'demo-only', authDomain: projectId + '.firebaseapp.com' }, 'claims');
const auth = getAuth(app); connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
const db = getFirestore(app); connectFirestoreEmulator(db, '127.0.0.1', 8080);
const results = [];
async function check(name, action) { try { await action(); results.push({ name, passed: true }); console.log('PASS ' + name); } catch (e) { results.push({ name, passed: false, error: e.message }); console.error('FAIL ' + name + ': ' + e.message); } }
try {
  for (const mode of ['true', 'false']) {
    await check('set_admin ' + mode + ' preserve claims and readback', async () => {
      const out = execFileSync(process.execPath, [fileURLToPath(new URL('../admin-tools/set_admin.js', import.meta.url)), uid, mode, projectId], { encoding: 'utf8', env: process.env });
      console.log(out.trim());
      assert.deepEqual((await getAdminAuth().getUser(uid)).customClaims, { course: 't13', retainedFlag: true, admin: mode === 'true' });
    });
    await check('fresh Auth token admin=' + mode + ' Firestore enforcement', async () => {
      const token = await getAdminAuth().createCustomToken(uid);
      await signInWithCustomToken(auth, token);
      const id = await getIdTokenResult(auth.currentUser, true);
      assert.equal(id.claims.admin, mode === 'true');
      assert.equal(id.claims.course, 't13');
      if (mode === 'true') assert.ok((await getDocs(collection(db, 'mahasiswa'))).size > 0);
      else await assert.rejects(getDocs(collection(db, 'mahasiswa')), e => e.code === 'permission-denied');
    });
  }
} finally {
  await terminate(db); await deleteApp(app); await getAdminAuth().deleteUser(uid); await deleteAdminApp(getApp());
  const report = { projectId, generatedAt: new Date().toISOString(), total: results.length, passed: results.filter(r => r.passed).length, failed: results.filter(r => !r.passed).length, results };
  writeFileSync(new URL('../documentation/security-evidence/claims-results.json', import.meta.url), JSON.stringify(report, null, 2));
  if (report.failed) process.exitCode = 1;
}
