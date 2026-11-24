'use strict';
// Trusted operator only. Never put service-account credentials in repository.
const { initializeApp: initializeAdminApp, applicationDefault, deleteApp: deleteAdminApp, getApp } = require('firebase-admin/app');
const { getAuth: getAdminAuth } = require('firebase-admin/auth');
const { isDeepStrictEqual } = require('node:util');
const [uid, mode, projectId] = process.argv.slice(2);
async function main() {
  if (!uid || uid.length > 128 || !['true', 'false'].includes(mode) || !projectId) {
    throw new Error('Usage: node set_admin.js <UID> <true|false> <PROJECT_ID>');
  }
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  if (host && (projectId !== 'demo-lkm-mahasiswa-t13' || host !== '127.0.0.1:9099')) {
    throw new Error('Emulator restricted to demo-lkm-mahasiswa-t13 at 127.0.0.1:9099');
  }
  if (!host && projectId.startsWith('demo-')) throw new Error('Demo project requires Auth emulator');
  if (!host && process.env.CONFIRM_ADMIN_PROJECT !== projectId) {
    throw new Error('Production requires CONFIRM_ADMIN_PROJECT matching explicit PROJECT_ID');
  }
  initializeAdminApp(host ? { projectId } : { projectId, credential: applicationDefault() });
  const user = await getAdminAuth().getUser(uid);
  const claims = { ...(user.customClaims || {}), admin: mode === 'true' };
  await getAdminAuth().setCustomUserClaims(uid, claims);
  const verified = (await getAdminAuth().getUser(uid)).customClaims;
  if (!isDeepStrictEqual(verified, claims)) throw new Error('Claim readback mismatch');
  console.log(JSON.stringify({ uid, projectId, admin: verified.admin, otherClaimsPreserved: true, readbackVerified: true, emulator: !!host }));
  console.log('Refresh ID token or logout/login. Revocation does not invalidate already-issued ID tokens immediately.');
  await deleteAdminApp(getApp());
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
