import admin from 'firebase-admin';
import serviceAccount from './firebase-service-account.json' with { type: 'json' };

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;

console.log('Firebase Admin inicializado correctamente');