import express from 'express';
import pool from '../config/database.js';

const router = express.Router();
export default router;

// Crear post de challenge
router.post('/api/challenge_posts', async (req, res) => {
  /*
   //challenge_id
         //challenge_id
        'category_id': categoryId,
        'description': description,
        'state': 'ACTIVE',
        'timer': null,
        //Created_at se genera en el backend
        'competitor_user_id': null,
        'joined_at': null,
        'accepted': null,
        //rater_id se asigna en el backend
        'stars': 0,
        'rated_at': null,
        //liked_user_id,
        'liked_at': null,
        //voted_for_user_id
        'voted_at': null,
        'firebase_uid': firebaseUid,
        'content_type': contentType,
        'content_url': contentUrl,
        'role': 'CREATOR',
   */
  const {
    category_id,
    description,
    state,
    timer,
    //created_at,
    competitor_user_id,
    joined_at,
    accepted,
    //stars,
    rated_at,
    //liked_user_id,
    liked_at,
    //voted_for_user_id
    voted_at,
    firebase_uid,
    content_type,
    content_url,
    role,
    views
  } = req.body;

  // Validar campos requeridos
  if (!firebase_uid  || !content_type) {
    return res.status(400).json({ error: 'Faltan campos requeridos: firebase_uid, content_type' });
  }

  try {

     
     // Incrementar contador de challenges creados por el usuario
    await pool.query(
    `UPDATE Users SET challenges_created = challenges_created + 1
    WHERE firebase_uid = $1`,
    [firebase_uid]
  );

    //obtener la hora de la maquina para insertarla como created_at
    const created_at = new Date().toISOString();
  
    const query = `
      INSERT INTO challenge (
       category_id, description, state, timer, 
       competitor_user_id, joined_at, accepted, 
       rated_at, liked_at, voted_at, created_at,

       firebase_uid, content_type, content_url, role, views
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
      RETURNING *;
    `;
   
    const values = [
      category_id || null,
      description || null,
      state || 'waiting',
      timer || null,
      competitor_user_id || null,
      joined_at || null,
      accepted || null,
      rated_at || null,
      liked_at || null,
      voted_at || null,
      created_at,
      firebase_uid,
      content_type,
      content_url || null,
      role || 'CREATOR',
      views,
    ];
   
     

    console.log('Insertando post con valores:', values); // Debug
    const result = await pool.query(query, values);
    console.log('Post creado exitosamente:', result.rows[0]); // Debug
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creando post:', err.stack);
    if (err.code === '23505') { // Unique violation
      return res.status(409).json({ error: 'Error de duplicación' });
    }
    if (err.code === '23503') { // Foreign key violation
      return res.status(400).json({ error: 'Categoría inválida' });
    }
    res.status(500).json({ error: `Error al crear post: ${err.message}` });
  }
});

// Obtener posts de challenges de un usuario
router.get('/api/challenge_posts/user/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;

  try {
    const result = await pool.query(
      `SELECT * FROM challenge WHERE firebase_uid = $1 AND (state = 'waiting' OR state = 'requested')`,
      [firebaseUid]
    );
    res.status(200).json(result.rows);
    //console.log('Posts obtenidos exitosamente para usuario:', firebaseUid); // Debug
    //Link del video del post
    const videoLinks = result.rows.map(post => post.content_url);
    console.log('Links de video de los posts:', videoLinks);
  } catch (err) {
    console.error('Error obteniendo posts de usuario:', err.stack);
    res.status(500).json({ error: `Error al obtener posts de usuario: ${err.message}` });
  }
});


// obtener los challenges que estan disponibles, es decir, que esten en estado de waiting, menos los del usuario
router.get('/api/challenge_posts/available/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;

  try {
    const result = await pool.query(
      `SELECT * FROM challenge WHERE state = 'waiting' AND firebase_uid != $1`,
      [firebaseUid]
    );
    res.status(200).json(result.rows);
  } catch (err) {
    console.error('Error obteniendo challenges disponibles:', err.stack);
    res.status(500).json({ error: `Error al obtener challenges disponibles: ${err.message}` });
  }
});

//obtener los challenges que un usuario está esperando
router.get('/api/challenge_posts/requested/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;
  try {
    const result = await pool.query(
      `SELECT * FROM challenge WHERE state = 'requested' AND competitor_user_id = $1`,
      [firebaseUid]
    );
    res.status(200).json(result.rows);
    console.log('Challenges solicitados obtenidos exitosamente para usuario:', firebaseUid); // Debug
  } catch (err) {
    console.error('Error obteniendo challenges solicitados:', err.stack);
    res.status(500).json({ error: `Error al obtener challenges solicitados: ${err.message}` });
  }
});


//obtener los challenges que un usuario está en progreso, es decir, que ya aceptó y ya está dentro
router.get('/api/challenge_posts/in_progress/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;
  try {
    const result = await pool.query(
      `SELECT * FROM challenge WHERE (state = 'in progress' OR state = 'finished') AND (competitor_user_id = $1 OR firebase_uid = $1)`,
      [firebaseUid]
    );
    res.status(200).json(result.rows);
    console.log('Challenges en progreso obtenidos exitosamente para usuario:', firebaseUid); // Debug
  } catch (err) {
    console.error('Error obteniendo challenges en progreso:', err.stack);
    res.status(500).json({ error: `Error al obtener challenges en progreso: ${err.message}` });
  }
});


//obtener los challenges que ya están en competencia, es decir, que ya estan en progreso pero el usuario no es creador ni competidor
router.get('/api/challenge_posts/ongoing/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;
  try {
    const result = await pool.query(
      `SELECT * FROM challenge WHERE state = 'in progress' AND firebase_uid != $1 AND competitor_user_id != $1`,
      [firebaseUid]
    );
    res.status(200).json(result.rows);
    console.log('Challenges en competencia obtenidos exitosamente para usuario:', firebaseUid); // Debug
  } catch (err) {
    console.error('Error obteniendo challenges en competencia:', err.stack);
    res.status(500).json({ error: `Error al obtener challenges en competencia: ${err.message}` });
  }
});


router.post('/api/challenge_posts/:challengeId/request', async (req, res) => {
  const { challengeId } = req.params;
  const { competitor_uid, competitor_content_url, competitor_content_type } = req.body;

  try {
    const result = await pool.query(
      `UPDATE challenge 
       SET 
         competitor_user_id = $1,
         competitor_content_url = $2,
         competitor_content_type = $3,
         state = 'requested' 
       WHERE challenge_id = $4 AND state = 'waiting' 
       RETURNING *`,
      [competitor_uid, competitor_content_url, competitor_content_type, challengeId]
    );

    if (result.rowCount === 0) {
      return res.status(400).json({ error: 'Reto no disponible o ya solicitado' });
    }

    res.status(200).json({ message: 'Solicitud enviada', challenge: result.rows[0] });
  } catch (err) {
    console.error('Error enviando solicitud:', err.stack);
    res.status(500).json({ error: 'Error al enviar solicitud' });
  }
});

// Aceptar solicitud
router.patch('/api/challenge_posts/:challengeId/accept', async (req, res) => {
  const { challengeId } = req.params;

  //joined_at con la hora de la maquina
  const joined_at = new Date().toISOString();

  try {
      //actualizar estado de challenge a in progress
      // adicionalmente, eliminar la notificacion de solicitud con estado 'challenge_requested'
    const result = await pool.query(
      `UPDATE challenge
        SET
          state = 'in progress',
          joined_at = $1
        WHERE challenge_id = $2 AND state = 'requested'
        RETURNING *`,
      [joined_at, challengeId]
    );
    if (result.rowCount === 0) {
      return res.status(400).json({ error: 'No hay solicitud pendiente' });
    }
    res.status(200).json({ message: 'Solicitud aceptada', challenge: result.rows[0] });
  } catch (err) {
    console.error('Error aceptando solicitud:', err.stack);
    res.status(500).json({ error: 'Error al aceptar solicitud' });
  }
});

// Rechazar solicitud
router.patch('/api/challenge_posts/:challengeId/reject', async (req, res) => {
  const { challengeId } = req.params;

  try {
    const result = await pool.query(
      `UPDATE challenge 
       SET 
         competitor_user_id = NULL,
         competitor_content_url = NULL,
         competitor_content_type = NULL,
         state = 'waiting' 
       WHERE challenge_id = $1 AND state = 'requested' 
       RETURNING *`,
      [challengeId]
    );

    if (result.rowCount === 0) {
      return res.status(400).json({ error: 'No hay solicitud pendiente' });
    }

    res.status(200).json({ message: 'Solicitud rechazada', challenge: result.rows[0] });
  } catch (err) {
    console.error('Error rechazando solicitud:', err.stack);
    res.status(500).json({ error: 'Error al rechazar solicitud' });
  }
});


// Obtener detalle completo del reto
router.get('/api/challenge_posts/:challengeId', async (req, res) => {
  const { challengeId } = req.params;
  try {
    const result = await pool.query(
      `SELECT 
         c.challenge_id,
         c.firebase_uid AS creator_uid,
         c.competitor_user_id,
         c.content_url,
         c.description,
         c.category_id,
         c.views,
         c.state,
         c.created_at,
         u.username AS creator_username,
         u.image AS creator_profile_image,
         cat.category_name,
         comp.username AS competitor_username,
        comp.image AS competitor_profile_image
       FROM challenge c
       JOIN users u ON c.firebase_uid = u.firebase_uid
       JOIN category cat ON c.category_id = cat.category_id
       LEFT JOIN users comp ON c.competitor_user_id = comp.firebase_uid
       WHERE c.challenge_id = $1`,
      [challengeId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Reto no encontrado' });
    }

    res.status(200).json(result.rows[0]);
  } catch (err) {
    console.error('Error obteniendo detalle del reto:', err);
    res.status(500).json({ error: 'Error interno' });
  }
});


// mostrar challenges en progreso de un usuario, ya sea como creador o como competidor
router.get('/api/challenge_posts/in_progress/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;
  try {
    const result = await pool.query(
      `SELECT 
         c.challenge_id,
         c.content_url AS creator_content_url,
         c.description,
         c.views,
         c.state,
         c.created_at,
         u1.username AS creator_username,
         u1.image AS creator_profile_image,
         u1.firebase_uid AS creator_uid,
         c.competitor_content_url,
         u2.username AS competitor_username,
         u2.image AS competitor_profile_image,
         u2.firebase_uid AS competitor_uid
       FROM challenge c
       JOIN users u1 ON c.firebase_uid = u1.firebase_uid
       LEFT JOIN users u2 ON c.competitor_user_id = u2.firebase_uid
       WHERE c.state = 'in progress'
         AND (c.firebase_uid = $1 OR c.competitor_user_id = $1)`,
      [firebaseUid]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/api/challenge_posts/ongoing', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT 
         c.challenge_id,
         c.content_url AS creator_content_url,
         c.description,
         c.views,
         c.state,
         c.created_at,
         u1.username AS creator_username,
         u1.image AS creator_profile_image,
         u1.firebase_uid AS creator_uid,
         c.competitor_content_url,
         u2.username AS competitor_username,
         u2.image AS competitor_profile_image,
         u2.firebase_uid AS competitor_uid
       FROM challenge c
       JOIN users u1 ON c.firebase_uid = u1.firebase_uid
       JOIN users u2 ON c.competitor_user_id = u2.firebase_uid
       WHERE c.state = 'in progress'`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Obtener calificación agregada para un usuario, promedio + cant de votos
router.get("/api/challenge_posts/:ratedUid/rating", async (req, res) => {
  const { ratedUid } = req.params;
  try {
    const query = `
     SELECT 
  COALESCE(ROUND(AVG(stars)::numeric, 2), 0) AS average_rating,
  COUNT(*) AS total_votes
FROM user_ratings
WHERE rated_uid = $1;

    `;

    const { rows } = await pool.query(query, [ratedUid]);

    res.json({
      ratedUid,
      average_rating: rows[0].average_rating,
      total_votes: rows[0].total_votes
    });
    console.log("Rating data sent:", rows[0]);
  } catch (err) {
    console.error("Error getting rating:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

//Update para calificar a un usuario
router.post("/api/challenge_posts/:ratedUid/rate", async (req, res) => {
  const { ratedUid } = req.params;
  const { rater_uid, stars } = req.body;

  if (!rater_uid || stars == null) {
    return res.status(400).json({ error: "Missing parameters" });
  }

  try {
    // Inserta o actualiza rating
    const upsertQuery = `
      INSERT INTO user_ratings (rated_uid, rater_uid, stars)
      VALUES ($1, $2, $3)
      ON CONFLICT (rated_uid, rater_uid)
      DO UPDATE SET stars = EXCLUDED.stars, rated_at = NOW()
      RETURNING *;
    `;
    await pool.query(upsertQuery, [ratedUid, rater_uid, stars]);

    // Obtener promedio y número de votos
    const ratingQuery = `
      SELECT 
        COALESCE(ROUND(AVG(stars)::numeric, 1), 0) AS average,
        COUNT(*) AS count
      FROM user_ratings
      WHERE rated_uid = $1;
    `;
    const { rows } = await pool.query(ratingQuery, [ratedUid]);

    res.json(rows[0]);

  } catch (err) {
    console.error("Error saving rating:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});






