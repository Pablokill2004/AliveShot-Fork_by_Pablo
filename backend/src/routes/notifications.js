// src/routes/notifications.js
import express from 'express';
import admin from '../config/firebaseAdmin.js';
import pool from '../config/database.js';

const router = express.Router();

// Ruta para enviar notificaciones de "seguir", y agregar a la tabla notifications
router.post('/api/notifications/follow', async (req, res) => {
  try {
    const { follower_uid, following_uid } = req.body;

    // Obtener nombre del seguidor (para personalizar la notificación)
    const followerResult = await pool.query(
      'SELECT username FROM users WHERE firebase_uid = $1',
      [follower_uid]
    );
    const followerName = followerResult.rows[0]?.username || 'Alguien';

    // Obtener token FCM del usuario seguido
    const followingResult = await pool.query(
      'SELECT fcm_token FROM users WHERE firebase_uid = $1',
      [following_uid]
    );

    const targetToken = followingResult.rows[0]?.fcm_token;

    if (!targetToken) {
      return res.status(404).json({ message: 'El usuario no tiene token FCM registrado' });
    }

    /* Insertar a la tabla notifications receiver_firebase_uid,
  sender_firebase_uid,
  type,
  message*/
  const message_in_notification = `@${followerName} comenzó a seguirte.`;
  try {
  const insertQuery = `
    INSERT INTO notifications (receiver_firebase_uid, sender_firebase_uid, type, message)
    VALUES ($1, $2, $3, $4)
  `;
  await pool.query(insertQuery, [following_uid, follower_uid, 'follow', message_in_notification]);
  console.log('Notificación guardada correctamente en la BD');
} catch (e) {
  console.error('Error al insertar notificación en la base de datos:', e);
  return res.status(500).json({ message: 'Error al guardar la notificación' });
}
// Crear mensaje FCM
    const message_to_FCM = {
      token: targetToken,
      notification: {
        title: 'Nuevo seguidor ',
        body: message_in_notification,
      },
      data: {
        type: 'follow',
        followerUid: follower_uid,
      },
    };

    // Enviar notificación
    await admin.messaging().send(message_to_FCM);

    return res.status(201).json({ message: 'Notificación enviada correctamente' });
  } catch (error) {
    console.error('Error al enviar notificación:', error);
    return res.status(500).json({ error: error.message });
  }
});


//eliminar notificacion de solicitud de desafio
router.delete('/api/notifications/challenge_request/:challengeId', async (req, res) => {
  const { challengeId } = req.params;
  try {
    await pool.query(
      'DELETE FROM notifications WHERE challenge_id = $1 AND type = $2',
      [challengeId, 'challenge_request']
    );
    res.json({ message: 'Notificación de solicitud de desafío eliminada' });
  } catch (error) {
    console.error('Error al eliminar notificación:', error);
    res.status(500).json({ error: 'Error al eliminar notificación' });
  }
});

// POST /api/notifications/challenge_request
router.post('/api/notifications/challenge_request', async (req, res) => {
  const { receiver_uid, sender_uid, challenge_id, message } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO notifications (
        receiver_firebase_uid, sender_firebase_uid, type, message, 
        challenge_id, is_read, created_at
      ) VALUES ($1, $2, 'challenge_request', $3, $4, false, NOW())
      RETURNING notification_id, challenge_id`,
      [receiver_uid, sender_uid, message, challenge_id]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creando notificación:', err);
    res.status(500).json({ error: 'Error al crear notificación' });
  }
});


// Ruta para enviar notificaciones en likes en Post -- En proceso
router.post('/api/notifications/likePost', async (req,res) => {
    try{
      const {liker_fid, post_fid} = req.body;
      // Obtener nombre del que le dio like
      const likerResult = await pool.query(
        'SELECT username FROM users WHERE firebase_uid = $1',
        [liker_fid]
      );
      const likerName = likerResult.rows[0]?.username || 'Alguien';

      // Obtener token FCM del autor del post
      const postResult = await pool.query(
        'SELECT author_uid FROM user_publishes_post_has_category WHERE id = $1',
        [post_fid]
      );
      const authorUid = postResult.rows[0]?.author_uid;

      if (!authorUid) {
        return res.status(404).json({ message: 'Post no encontrado' });
      }
      // Obtener token FCM del autor del post
      const authorResult = await pool.query(
        'SELECT fcm_token FROM users WHERE firebase_uid = $1',
        [authorUid]
      );
      const targetToken = authorResult.rows[0]?.fcm_token;

      if (!targetToken) {
        return res.status(404).json({ message: 'El autor del post no tiene token FCM registrado' });
      }

      // Crear mensaje FCM
      const message = {
        token: targetToken,
        notification: {
          title: 'Nuevo like ',
          body: `${likerName} le dio like a tu publicación.`,
        },
        data: {
          type: 'like',
          likerUid: liker_uid,
          postId: post_id,
        },
      };

      // Enviar notificación
      await admin.messaging().send(message);

      return res.status(201).json({ message: 'Notificación enviada correctamente' });
    } catch(e){
      return res.error(500).json({error: e.message});
    }
});

// Obtener notificaciones de un usuario
router.get('/api/notifications/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;
  try {
    const result = await pool.query(
      `SELECT notification_id, type, message, is_read, created_at, challenge_id
       FROM notifications 
       WHERE receiver_firebase_uid = $1 
       ORDER BY created_at DESC`,
      [firebaseUid]
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Marcar una notificación como leída
router.put('/api/notifications/:id/read', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query(
      'UPDATE notifications SET is_read = true WHERE notification_id = $1',
      [id] // ✅ corregido
    );
    res.json({ message: 'Notificación marcada como leída' });
  } catch (error) {
    console.error('Error al marcar como leída:', error);
    res.status(500).json({ error: 'Error al marcar como leída' });
  }
});

// Marcar todas como leídas
router.put('/api/notifications/read-all/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;
  try {
    await pool.query(
      'UPDATE notifications SET is_read = true WHERE receiver_firebase_uid = $1',
      [firebaseUid]
    );
    res.json({ message: 'Todas las notificaciones marcadas como leídas' });
  } catch (error) {
    console.error('Error al marcar todas:', error);
    res.status(500).json({ error: 'Error al marcar todas como leídas' });
  }
});

// Eliminar una notificación
router.delete('/api/notifications/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query(
      'DELETE FROM notifications WHERE notification_id = $1',
      [id] 
    );
    res.json({ message: 'Notificación eliminada' });
  } catch (error) {
    console.error('Error al eliminar notificación:', error);
    res.status(500).json({ error: 'Error al eliminar notificación' });
  }
});

//ruta para obtener el Id de la notificacion
router.get('/api/notifications/id/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;
  try {
    const result = await pool.query(
      'SELECT notification_id FROM notifications WHERE receiver_firebase_uid = $1',
      [firebaseUid]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener ID de notificación:', error);
    res.status(500).json({ error: 'Error al obtener ID de notificación' });
  }
});


/* notificacion al solicitante de que su solicitud fue aceptada*/
 router.post('/api/notifications/challenge_accepted', async (req, res) => {
  const { receiver_uid, sender_uid, challenge_id, message } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO notifications (
        receiver_firebase_uid, sender_firebase_uid, type, message, 
        challenge_id, is_read, created_at
      ) VALUES ($1, $2, 'challenge_accepted', $3, $4, false, NOW())
      RETURNING notification_id, challenge_id`,
      [receiver_uid, sender_uid, message, challenge_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creando notificación:', err);
    res.status(500).json({ error: 'Error al crear notificación' });
  }
});


export default router;
router.get('/', (req, res) => {
  res.send('API funcionando correctamente');
});
