import express from 'express';
import pool from '../config/database.js';

const router = express.Router();
export default router;

// GET /api/challenge_posts/in_progress_detail/:challengeId
router.get('/api/challenge_posts/in_progress_detail/:challengeId', async (req, res) => {
  const { challengeId } = req.params;

  try {
    const result = await pool.query(
      `SELECT 
  c.challenge_id,
  c.content_url AS creator_content_url,
  c.competitor_content_url,
  c.description,
  c.views,
  c.state,
  c.created_at,
  c.winner_uid,
  c.winner_role,
  c.finished_at,
  c.joined_at,


  -- Creador
  u1.username AS creator_username,
  u1.image AS creator_profile_image,
  u1.firebase_uid AS creator_uid,

  -- Competidor
  u2.username AS competitor_username,
  u2.image AS competitor_profile_image,
  u2.firebase_uid AS competitor_uid,

  -- Votos
  COALESCE(SUM(CASE WHEN cv.voted_for_role = 'CREATOR' THEN 1 END), 0) AS creator_votes,
  COALESCE(SUM(CASE WHEN cv.voted_for_role = 'JOINER' THEN 1 END), 0) AS joiner_votes

FROM challenge c
JOIN users u1 ON c.firebase_uid = u1.firebase_uid
JOIN users u2 ON c.competitor_user_id = u2.firebase_uid

LEFT JOIN challengevotes cv
  ON cv.challenge_id = c.challenge_id

WHERE c.challenge_id = $1 
  AND (c.state = 'in progress' OR c.state = 'finished')

GROUP BY 
  c.challenge_id,
  u1.username, u1.image, u1.firebase_uid,
  u2.username, u2.image, u2.firebase_uid;
`,
      [challengeId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Reto no encontrado o no está en curso' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error cargando detalle in_progress:', err.stack);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Ruta para sumar votos a una competencia(voto para un competidor o para el creador)
// Ruta para sumar o cambiar votos (upsert)
router.post("/api/on_challenge/:challengeId/vote", async (req, res) => {
  try {
    const { challengeId } = req.params;
    const { voted_for_role, voter_uid } = req.body;

    // Validar role
    if (!["CREATOR", "JOINER"].includes(voted_for_role)) {
      return res.status(400).json({ error: "Rol inválido" });
    }

    // Validar datos mínimos
    if (!voter_uid) {
      return res.status(400).json({ error: "voter_uid requerido" });
    }

    // Verificar que el challenge existe y no esté finalizado
    const challengeResult = await pool.query(
      "SELECT state, firebase_uid, competitor_user_id FROM challenge WHERE challenge_id = $1",
      [challengeId]
    );

    if (challengeResult.rows.length === 0) {
      return res.status(404).json({ error: "Challenge no encontrado" });
    }

    const challenge = challengeResult.rows[0];

    if (challenge.state === 'finished') {
      return res.status(400).json({ error: "El reto ya terminó, no se puede votar" });
    }

    // Upsert: insertar o actualizar el voto del usuario para este challenge
    await pool.query(
      `INSERT INTO challengevotes (voter_uid, challenge_id, voted_for_role, voted_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (voter_uid, challenge_id)
       DO UPDATE SET voted_for_role = EXCLUDED.voted_for_role,
                     voted_at = EXCLUDED.voted_at;`,
      [voter_uid, challengeId, voted_for_role]
    );

    // Obtener conteo actualizado
    const counts = await pool.query(
      `SELECT
         SUM(CASE WHEN voted_for_role = 'CREATOR' THEN 1 ELSE 0 END) AS creator_votes,
         SUM(CASE WHEN voted_for_role = 'JOINER' THEN 1 ELSE 0 END) AS joiner_votes
       FROM challengevotes
       WHERE challenge_id = $1;`,
      [challengeId]
    );

    return res.status(200).json({
      message: "Voto registrado",
      votes: counts.rows[0]
    });

  } catch (error) {
    console.error("Error al votar:", error);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

// Ruta para obtener votos del creador
router.get("/api/on_challenge/:challengeId/votes/creator", async (req, res) => {
  try {
    const { challengeId } = req.params;
    const counts = await pool.query(
      `SELECT 
          SUM(CASE WHEN voted_for_role = 'CREATOR' THEN 1 ELSE 0 END) AS creator_votes 
        FROM ChallengeVotes
        WHERE challenge_id = $1`,
      [challengeId]
    );
    return res.status(200).json({
      creator_votes: counts.rows[0].creator_votes || 0,
    });
  } catch (error) {
    console.error("Error al obtener votos del creador:", error);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});
// Ruta para obtener votos del competidor
router.get("/api/on_challenge/:challengeId/votes/joiner", async (req, res) => {
  try {
    const { challengeId } = req.params;
    const counts = await pool.query(
      `SELECT 
          SUM(CASE WHEN voted_for_role = 'JOINER' THEN 1 ELSE 0 END) AS joiner_votes 
        FROM ChallengeVotes
        WHERE challenge_id = $1`,
      [challengeId]
    );
    return res.status(200).json({
      joiner_votes: counts.rows[0].joiner_votes || 0,
    });
  } catch (error) {
    console.error("Error al obtener votos del competidor:", error);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
})

// Endpoint para incrementar las vistas de un reto en curso
router.post('/api/challenge_posts/in_progress_detail/:challengeId/increment_views', async (req, res) => {
  const { challengeId } = req.params;

  try {
    const result = await pool.query(
      `UPDATE challenge
       SET views = views + 1
       WHERE challenge_id = $1 AND state = 'in progress'
       RETURNING views;`,
      [challengeId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Reto no encontrado o no está en curso' });
    }
    } catch (err) {
      console.error('Error incrementando vistas:',  err.stack);
      return res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// Ruta para calcular el ganador de un reto

/*router.post('/challenges/:challengeId/calculate-winner', async (req, res) => {
  const { challengeId } = req.params;

  try {
    // 1. Obtener votos
    const creatorVotesRes = await pool.query(
      `SELECT COUNT(*) AS votes 
       FROM challengevotes 
       WHERE challenge_id = $1 AND voted_for_role = 'CREATOR'`,
      [challengeId]
    );

    const joinerVotesRes = await pool.query(
      `SELECT COUNT(*) AS votes 
       FROM challengevotes 
       WHERE challenge_id = $1 AND voted_for_role = 'JOINER'`,
      [challengeId]
    );

    const creatorVotes = parseInt(creatorVotesRes.rows[0].votes);
    const joinerVotes = parseInt(joinerVotesRes.rows[0].votes);

    // 2. Obtener información del reto
    const challengeRes = await pool.query(
      `SELECT firebase_uid, competitor_user_id
       FROM challenge
       WHERE challenge_id = $1`,
      [challengeId]
    );

    if (challengeRes.rows.length === 0) {
      return res.status(404).json({ error: "Challenge not found" });
    }

    const challenge = challengeRes.rows[0];
    let winnerUid = null;
    let winnerRole = "TIE";

    // 3. Determinar ganador
    if (creatorVotes > joinerVotes) {
      winnerUid = challenge.firebase_uid;
      winnerRole = "CREATOR";
    } else if (joinerVotes > creatorVotes) {
      winnerUid = challenge.competitor_user_id;
      winnerRole = "JOINER";
    }

    // 4. Guardar ganador
      // 4. Guardar ganador de forma idempotente: solo incrementar si aún no existe ganador
      if (winnerUid) {
        // Intentar actualizar winner_uid sólo si aún es NULL (operación atómica)
        const updateRes = await pool.query(
          `UPDATE challenge
           SET winner_uid = $1
           WHERE challenge_id = $2 AND winner_uid IS NULL
           RETURNING winner_uid`,
          [winnerUid, challengeId]
        );

        if (updateRes.rowCount > 0) {
          // Se actualizó por primera vez: incrementar contador de retos ganados del usuario
          await pool.query(
            `UPDATE users
             SET challenges_won = COALESCE(challenges_won, 0) + 1
             WHERE firebase_uid = $1`,
            [winnerUid]
          );
          console.log(`Winner set and user incremented: UID=${winnerUid}, Role=${winnerRole}`);
        } else {
          // Ya había un ganador guardado; no incrementamos de nuevo
          console.log(`Winner already set for challenge ${challengeId}, no increment performed.`);
        }
      } else {
        // Empate: no winner_uid to set; no user increment
        console.log(`No winner (tie) for challenge ${challengeId}`);
      }

      return res.json({
        winner_uid: winnerUid,
        winner_role: winnerRole,
        creator_votes: creatorVotes,
        joiner_votes: joinerVotes,
      });

  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Error calculating winner" });
  }
});*/

// get challenges/$winnerUid/username
router.get('/api/challenges/:winnerUid/username', async (req, res) => {
  const { winnerUid } = req.params;
  try {
    const result = await pool.query(
      `SELECT username FROM users WHERE firebase_uid = $1`,
      [winnerUid]
    );
     console.log("Winner username fetched:", result.rows[0].username);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    // Return the username
    return res.json({ username: result.rows[0].username });
  } catch (err) {
    console.error('Error obteniendo username del ganador:', err.stack);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.post("/api/challenges/user/streak/update", async (req, res) => {
  const { firebaseUid } = req.body;

  try {
    const result = await pool.query(
      `SELECT streak, last_streak_date FROM users WHERE firebase_uid = $1`,
      [firebaseUid]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    const user = result.rows[0];

    const today = new Date();
    const last = user.last_streak_date ? new Date(user.last_streak_date) : null;

    let newStreak = user.streak;

    if (!last) {
      newStreak = 1;
    } else {
      const diff =
        Math.floor((today - last) / (1000 * 60 * 60 * 24));

      if (diff === 1) newStreak += 1;
      else if (diff > 1) newStreak = 1;
    }

    await pool.query(
      `UPDATE users
       SET streak = $1, last_streak_date = CURRENT_DATE
       WHERE firebase_uid = $2`,
      [newStreak, firebaseUid]
    );

    return res.json({ streak: newStreak });

  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Internal error" });
  }
});







