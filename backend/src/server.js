import express from 'express';
import cors from 'cors';
import pool from './config/database.js';
import notificationsRouter from './routes/notifications.js';
import compete from './routes/compete.js';
import onChallenge from './routes/on_challenge.js';

const app = express();
const PORT =  parseInt(process.env.PORT) || 8080;

app.use(cors());
app.use(express.json()); 


app.get('/', (req, res) => {
  res.send('API funcionando correctamente');
});

// Endpoint para crear o actualizar un usuario
app.post('/api/users', async (req, res) => {
  const {
    firebase_uid,
    email,
    name,
    last_name,
    birthday,
    gender,
    is_active,
    is_admin,
    streak,
    image,
    image_header,
    title,
    bio,
    followers,
    following,
    likes,
    address,
    phone,
    username,
  } = req.body;

  try {
    const query = `
      INSERT INTO Users (
        firebase_uid, email, name, last_name, birthday, gender, is_active, is_admin,
        streak, image, image_header, title, bio, followers, following, likes,
        address, phone, username
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
      RETURNING *;
    `;
    const values = [
      firebase_uid, email, name, last_name, birthday, gender, is_active, is_admin,
      streak, image, image_header, title, bio, followers, following, likes,
      address, phone, username,
    ];
    const result = await pool.query(query, values);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al guardar el usuario' });
  }
});

/**
 * Endpoint para actualizar un usuario existente
 */
app.put('/api/users/:firebase_uid', async (req, res) => {
  const { firebase_uid } = req.params;
  const updates = req.body; // todos los campos enviados desde Flutter

  try {
    // Validar que al menos haya un campo a actualizar
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No se enviaron campos para actualizar' });
    }

    // Construir dinámicamente el SET
    const fields = [];
    const values = [];
    let idx = 1;

    for (const [key, value] of Object.entries(updates)) {
      fields.push(`${key} = $${idx}`);
      values.push(value);
      idx++;
    }

    // Agregar firebase_uid al final
    values.push(firebase_uid);

    const query = `
      UPDATE Users
      SET ${fields.join(', ')}
      WHERE firebase_uid = $${idx}
      RETURNING *;
    `;

    const result = await pool.query(query, values);

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    res.status(200).json(result.rows[0]);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al actualizar el usuario' });
  }
});

// Dentro de app.get('/api/users/:firebase_uid', async (req, res) => {
app.get('/api/users/:firebase_uid', async (req, res) => {
  const { firebase_uid } = req.params;

  try {
    const result = await pool.query('SELECT * FROM Users WHERE firebase_uid = $1', [firebase_uid]);
    if (result.rows.length > 0) {
      res.json(result.rows[0]);
    } else {
      res.status(404).json({ error: 'Usuario no encontrado' });
    }
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al buscar el usuario' });
  }
});

//subir una historia
app.post('/api/stories', async (req, res) => {
  const { firebase_uid, category_id, content_type, caption } = req.body;
  // Nota: content_url se genera en Flutter con Firebase Storage; aquí solo guardamos la URL proporcionada
  try {
    const query = `
      INSERT INTO Stories (firebase_uid, category_id, content_type, content_url, caption)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
    `;
    const values = [firebase_uid, category_id, content_type, req.body.content_url, caption || ''];
    const result = await pool.query(query, values);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al crear historia' });
  }
});

// Endpoint para obtener historias del usuario
app.get('/api/stories/:firebase_uid', async (req, res) => {
  const { firebase_uid } = req.params;
  try {
    const result = await pool.query(
      'SELECT * FROM Stories WHERE firebase_uid = $1 AND expires_at > NOW() ORDER BY created_at DESC',
      [firebase_uid]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al obtener historias' });
  }
});

//obtener las historias de un usuario
app.get('/api/stories/user/:firebaseUid', async (req, res) => {
  const { firebaseUid } = req.params;

  try {
    const query = `
      SELECT * FROM Stories
      WHERE firebase_uid = $1
      AND expires_at > NOW()
      ORDER BY created_at DESC;
    `;
    const result = await pool.query(query, [firebaseUid]);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error al obtener historias del usuario:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});


// endpoint solo para obtener las historias de los usuarios que SIGUE 
app.get('/api/stories/following/:firebase_uid', async (req, res) => {
  const { firebase_uid } = req.params;
  try {
    const query = `
      SELECT s.*, u.username, u.image as user_image
      FROM Stories s
      JOIN Follows f ON s.firebase_uid = f.following_firebase_uid
      JOIN Users u ON s.firebase_uid = u.firebase_uid
      WHERE f.follower_firebase_uid = $1 AND s.expires_at > NOW()
      ORDER BY s.created_at DESC;
    `;
    const result = await pool.query(query, [firebase_uid]);
    res.json(result.rows);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al obtener historias de usuarios seguidos' });
  }
});

// Buscar usuario por username (LIKE para coincidencias parciales)
app.get('/api/users/search/:username', async (req, res) => {
  const { username } = req.params;
  try {
    const query = `
      SELECT firebase_uid, username, name, last_name, image
      FROM Users
      WHERE username ILIKE $1
      LIMIT 10;
    `;
    const result = await pool.query(query, [`%${username}%`]);
    res.json(result.rows);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error en la búsqueda de usuarios' });
  }
});


// Endpoint para obtener los posts que un usuario ha dado like
app.get('/api/users/:firebaseUid/liked-posts', async (req, res) => {
  const { firebaseUid } = req.params;

  try {
    // Obtener los post_id de la tabla user_gives_like_receives_post
    const likesResult = await pool.query(
      'SELECT post_id FROM user_gives_like_receives_post WHERE firebase_uid = $1',
      [firebaseUid]
    );
    const postIds = likesResult.rows.map(row => row.post_id);

    if (postIds.length === 0) {
      return res.status(200).json([]);
    }

    // Obtener los detalles de los posts desde la tabla user_publishes_post_has_category
    const postsResult = await pool.query(
      `
      SELECT 
        p.post_id AS id,
        p.firebase_uid,
        p.content_url,
        p.description,
        p.content_type,
        p.created_at,
        p.category_id,
        p.title,
        u.username,
        u.image AS profile_image,
        u.name,
        u.last_name
      FROM user_publishes_post_has_category p
      JOIN Users u ON p.firebase_uid = u.firebase_uid
      WHERE p.post_id = ANY($1)
      ORDER BY p.created_at DESC
      `,
      [postIds]
    );

    const posts = postsResult.rows.map(post => ({
      id: post.id,
      firebase_uid: post.firebase_uid,
      content_url: post.content_url,
      description: post.description,
      content_type: post.content_type,
      created_at: post.created_at,
      category_id: post.category_id,
      title: post.title,
      username: post.username,
      profile_image: post.profile_image,
      name: post.name,
      last_name: post.last_name,
    }));

    res.status(200).json(posts);
  } catch (error) {
    console.error('Error fetching liked posts:', error);
    res.status(500).json({ error: 'Error al obtener los posts con likes' });
  }
});
// Crear post
app.post('/api/posts', async (req, res) => {
  const {
    firebase_uid,
    category_id,
    title,
    description,
    content_type,
    content_url,
  } = req.body;

  // Validar campos requeridos
  if (!firebase_uid || !title || !content_type) {
    return res.status(400).json({ error: 'Faltan campos requeridos: firebase_uid, title, content_type' });
  }

  try {
    const query = `
      INSERT INTO User_Publishes_Post_Has_Category (
        firebase_uid, category_id, title, description, content_type, content_url
      )
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *;
    `;
    const values = [
      firebase_uid,
      category_id || null,
      title,
      description || null,
      content_type,
      content_url || null,
    ];
    
    //console.log('Insertando post con valores:', values); // Debug
    const result = await pool.query(query, values);
    //console.log('Post creado exitosamente:', result.rows[0]); // Debug
    
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

//Obtener todos los posts de un usuario
app.get('/api/posts/user/:firebase_uid', async (req, res) => {
  const { firebase_uid } = req.params;
  
  try {
    const query = `
      SELECT 
        p.*, 
        u.username, 
        u.image as user_image,
        u.name,
        u.last_name,
        c.category_name
      FROM User_Publishes_Post_Has_Category p
      JOIN Users u ON p.firebase_uid = u.firebase_uid
      LEFT JOIN Category c ON p.category_id = c.category_id
      WHERE p.firebase_uid = $1
      ORDER BY p.created_at DESC;
    `;
    
    //console.log('Obteniendo posts para usuario:', firebase_uid); // Debug
    const result = await pool.query(query, [firebase_uid]);
    //console.log(`Encontrados ${result.rows.length} posts`); // Debug
    
    res.json(result.rows);
  } catch (err) {
    //console.error('Error obteniendo posts del usuario:', err.stack);
    res.status(500).json({ error: 'Error al obtener posts del usuario' });
  }
});

//eliminar un post, en cascada
app.delete('/api/posts/:post_id', async (req, res) => {
  const { post_id } = req.params;
  try {
    // Eliminar el post, en cascada, es decir, eliminando los likes asociados y comentarios
    const deleteQuery = 'DELETE FROM User_Publishes_Post_Has_Category WHERE post_id = $1 RETURNING *;';
    const result = await pool.query(deleteQuery, [post_id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Post no encontrado' });
    }
    res.status(200).json({ message: 'Post eliminado exitosamente' });
  } catch (err) {
    console.error('Error al eliminar post:', err.stack);
    res.status(500).json({ error: 'Error al eliminar el post' });
  }
});


// Endpoint para seguir a un usuario
app.post('/api/follow', async (req, res) => {
  const { follower_firebase_uid, following_firebase_uid } = req.body;

  // Validar que no sea el mismo usuario
  if (follower_firebase_uid === following_firebase_uid) {
    return res.status(400).json({ error: 'No puedes seguirte a ti mismo' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Verificar si la relación ya existe
    const checkFollow = await client.query(
      'SELECT follow_id FROM Follows WHERE follower_firebase_uid = $1 AND following_firebase_uid = $2',
      [follower_firebase_uid, following_firebase_uid]
    );
    if (checkFollow.rows.length > 0) {
      return res.status(400).json({ error: 'Ya sigues a este usuario' });
    }

    // Insertar en Follows
    await client.query(
      'INSERT INTO Follows (follower_firebase_uid, following_firebase_uid) VALUES ($1, $2)',
      [follower_firebase_uid, following_firebase_uid]
    );

    // Incrementar followers del seguido
    await client.query(
      'UPDATE Users SET followers = followers + 1 WHERE firebase_uid = $1',
      [following_firebase_uid]
    );

    // Incrementar following del seguidor
    await client.query(
      'UPDATE Users SET following = following + 1 WHERE firebase_uid = $1',
      [follower_firebase_uid]
    );

    await client.query('COMMIT');
    res.status(201).json({ message: 'Usuario seguido exitosamente' });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error al seguir usuario:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  } finally {
    client.release();
  }
});

// endpoint para dejar de seguir a un usuario
app.delete('/api/unfollow', async (req, res) => {
  const { follower_firebase_uid, following_firebase_uid } = req.body;

  // Validar que no sea el mismo usuario
  if (follower_firebase_uid === following_firebase_uid) {
    return res.status(400).json({ error: 'No puedes dejar de seguirte a ti mismo' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Verificar si la relación existe
    const checkFollow = await client.query(
      'SELECT follow_id FROM Follows WHERE follower_firebase_uid = $1 AND following_firebase_uid = $2',
      [follower_firebase_uid, following_firebase_uid]
    );
    if (checkFollow.rows.length === 0) {
      return res.status(400).json({ error: 'No sigues a este usuario' });
    }

    // Eliminar de Follows
    await client.query(
      'DELETE FROM Follows WHERE follower_firebase_uid = $1 AND following_firebase_uid = $2',
      [follower_firebase_uid, following_firebase_uid]
    );

    // Decrementar followers del seguido
    await client.query(
      'UPDATE Users SET followers = followers - 1 WHERE firebase_uid = $1 AND followers > 0',
      [following_firebase_uid]
    );

    // Decrementar following del seguidor
    await client.query(
      'UPDATE Users SET following = following - 1 WHERE firebase_uid = $1 AND following > 0',
      [follower_firebase_uid]
    );

    await client.query('COMMIT');
    res.status(200).json({ message: 'Usuario dejado de seguir exitosamente' });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error al dejar de seguir usuario:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  } finally {
    client.release();
  }
});


// endpoint para verificar si un usuario sigue a otro
app.get('/api/follow/check', async (req, res) => {
  const { follower, following } = req.query;

  try {
    const query = `
      SELECT EXISTS (
        SELECT 1 FROM Follows
        WHERE follower_firebase_uid = $1 AND following_firebase_uid = $2
      ) as following;
    `;
    const result = await pool.query(query, [follower, following]);
    res.status(200).json({ following: result.rows[0].following });
  } catch (error) {
    console.error('Error al verificar seguimiento:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});


// Endpoint para obtener la lista de seguidores de un usuario
app.get('/api/users/:firebase_uid/followers', async (req, res) => {
  const { firebase_uid } = req.params;

  try {
    const result = await pool.query(
      'SELECT u.firebase_uid, u.username, u.name, u.last_name, u.image ' +
      'FROM Follows f ' +
      'JOIN Users u ON f.follower_firebase_uid = u.firebase_uid ' +
      'WHERE f.following_firebase_uid = $1 ' +
      'ORDER BY f.created_at DESC',
      [firebase_uid]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al obtener seguidores' });
  }
});

// Endpoint para obtener la lista de seguidos de un usuario
app.get('/api/users/:firebase_uid/following', async (req, res) => {
  const { firebase_uid } = req.params;

  try {
    const result = await pool.query(
      'SELECT u.firebase_uid, u.username, u.name, u.last_name, u.image ' +
      'FROM Follows f ' +
      'JOIN Users u ON f.following_firebase_uid = u.firebase_uid ' +
      'WHERE f.follower_firebase_uid = $1 ' +
      'ORDER BY f.created_at DESC',
      [firebase_uid]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al obtener seguidos' });
  }
});


/*enpoint para insertar comentario en un post.*/

app.post('/api/comments', async (req, res) => {
  const { firebase_uid, post_id, content } = req.body;
  if (!firebase_uid || !post_id || !content) {
    return res.status(400).json({ error: 'Faltan campos requeridos: firebase_uid, post_id, content' });
  }
  try {
    const query = `
      INSERT INTO User_Does_Comment_IsSetTo_Post (firebase_uid, post_id, content)
      VALUES ($1, $2, $3)
      RETURNING *;
    `;
    const values = [firebase_uid, post_id, content];
    const result = await pool.query(query, values);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al crear comentario' });
  }
});

// endpoint para obtener los comentarios de un post
app.get('/api/comments/post/:post_id', async (req, res) => {
  const { post_id } = req.params;
  try {
    const query = `
      SELECT c.*, u.username, u.image as user_image
      FROM User_Does_Comment_IsSetTo_Post c
      JOIN Users u ON c.firebase_uid = u.firebase_uid
      WHERE c.post_id = $1
      ORDER BY c.comment_date DESC;
    `;
    const result = await pool.query(query, [post_id]);
    res.json(result.rows);
  } catch (err) {
    console.error(err.stack);
    res.status(500).json({ error: 'Error al obtener comentarios del post' });
  }
});

// Endpoint para agregar un like
app.post('/api/likes', async (req, res) => {
  const { firebaseUid, postId } = req.body;

  try {
    const query = `
      INSERT INTO User_Gives_Like_Receives_Post (firebase_uid, post_id)
      VALUES ($1, $2)
      ON CONFLICT ON CONSTRAINT user_gives_like_receives_post_firebase_uid_post_id_key
      DO NOTHING
      RETURNING *;
    `;
    const result = await pool.query(query, [firebaseUid, postId]);
    if (result.rowCount === 0) {
      return res.status(400).json({ message: 'Like ya existe o no se pudo agregar' });
    }
    res.status(201).json({ message: 'Like agregado', like: result.rows[0] });
  } catch (error) {
    console.error('Error al agregar like:', error);
    res.status(500).json({ message: 'Error en el servidor', error });
  }
});

// Endpoint para quitar un like
app.delete('/api/likes', async (req, res) => {
  const { firebaseUid, postId } = req.body;

  try {
    const query = `
      DELETE FROM User_Gives_Like_Receives_Post
      WHERE firebase_uid = $1 AND post_id = $2
      RETURNING *;
    `;
    const result = await pool.query(query, [firebaseUid, postId]);
    if (result.rowCount === 0) {
      return res.status(400).json({ message: 'No existe el like para eliminar' });
    }
    res.status(200).json({ message: 'Like eliminado', like: result.rows[0] });
  } catch (error) {
    console.error('Error al quitar like:', error);
    res.status(500).json({ message: 'Error en el servidor', error });
  }
});

//endpoint para contar los likes de un post
app.get('/api/likes/count', async (req, res) => {
  const { postId } = req.query;
  try {
    const query = `
      SELECT COUNT(*) as count
      FROM User_Gives_Like_Receives_Post
      WHERE post_id = $1;
    `;
    const result = await pool.query(query, [postId]);
    res.status(200).json({ count: parseInt(result.rows[0].count) });
  } catch (error) {
    res.status(500).json({ message: 'Error en el servidor', error });
  }
});


//endpoint para verificar si un usuario le dio like a un post
app.get('/api/likes/check', async (req, res) => {
  const { postId, firebaseUid } = req.query;
  try {
    const query = `
      SELECT EXISTS (
        SELECT 1 FROM User_Gives_Like_Receives_Post
        WHERE firebase_uid = $1 AND post_id = $2
      ) as liked;
    `;
    const result = await pool.query(query, [firebaseUid, postId]);
    res.status(200).json({ liked: result.rows[0].liked });
  } catch (error) {
    res.status(500).json({ message: 'Error en el servidor', error });
  }
});


//endpoint para mostrar todos los usuarios que le dieron like a un post
app.get('/api/likes/post/:postId/users', async (req, res) => {
  const { postId } = req.params;
  try {
    const query = `
      SELECT u.firebase_uid, u.username, u.name, u.last_name, u.image
      FROM User_Gives_Like_Receives_Post l
      JOIN Users u ON l.firebase_uid = u.firebase_uid
      WHERE l.post_id = $1;
    `;
    const result = await pool.query(query, [postId]);
    res.status(200).json(result.rows);
  } catch (error) {
    res.status(500).json({ message: 'Error en el servidor', error });
  }
});

//endpoint para actualizar el token FCM de un usuario
app.put('/api/users/:firebaseUid/token', async (req, res) => {
  const { firebaseUid } = req.params;
  const { fcm_token } = req.body;

  try {
    // Verificar que los datos vengan bien
    if (!fcm_token) {
      return res.status(400).json({ error: 'Token FCM no proporcionado' });
    }

    // Actualizar en la base de datos (ejemplo usando pg)
    const result = await pool.query(
      'UPDATE users SET fcm_token = $1 WHERE firebase_uid = $2 RETURNING *',
      [fcm_token, firebaseUid]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    res.status(200).json({ message: 'Token actualizado correctamente', user: result.rows[0] });
  } catch (error) {
    console.error('Error al actualizar token:', error);
    res.status(500).json({ error: 'Error al actualizar token' });
  }
});

// Endpoint para obtener todos los posts de todos los usuarios
// Endpoint: obtener feed (últimos 20 posts de usuarios seguidos)
// Si no sigue a nadie → feed global paginado

app.get('/api/allPosts/users/feed', async (req, res) => {
  const {firebase_uid,  page = 0 } = req.query;
  console.log("Obteniendo feed para usuario:", firebase_uid, "Página:", page);  
  if (!firebase_uid) {
    return res.status(400).json({ error: "firebase_uid es requerido" });
  }

  const limit = 20;
  const offset = page * limit;

  try {
    // Obtener a quién sigue el usuario
    const followQuery = `
      SELECT following_firebase_uid 
      FROM Follows 
      WHERE follower_firebase_uid = $1;
    `;
    const followsResult = await pool.query(followQuery, [firebase_uid]);

    const followingList = followsResult.rows.map(row => row.following_firebase_uid);

    let postsQuery;
    let params;

    // Si NO sigue a nadie, feed global PÁGINADO
    if (followingList.length === 0) {
      postsQuery = `
        SELECT 
          p.*, 
          u.username, 
          u.image AS user_image,
          u.name,
          u.last_name,
          c.category_name
        FROM User_Publishes_Post_Has_Category p
        JOIN Users u ON p.firebase_uid = u.firebase_uid
        LEFT JOIN Category c ON p.category_id = c.category_id
        WHERE p.firebase_uid = $1
        ORDER BY p.created_at DESC
        LIMIT $2 OFFSET $3;
      `;
      params = [firebase_uid, limit, offset];
    } else {
      // si sigue a usuarios, obtener solo sus posts
      postsQuery = `
        SELECT 
          p.*, 
          u.username, 
          u.image AS user_image,
          u.name,
          u.last_name,
          c.category_name
        FROM User_Publishes_Post_Has_Category p
        JOIN Users u ON p.firebase_uid = u.firebase_uid
        LEFT JOIN Category c ON p.category_id = c.category_id
        WHERE p.firebase_uid = ANY($1) OR p.firebase_uid = $2
        ORDER BY p.created_at DESC
        LIMIT $3 OFFSET $4;
      `;
      params = [followingList,firebase_uid, limit, offset];
    }

    const postsResult = await pool.query(postsQuery, params);
   // console.log("Posts obtenidos para el feed:", postsResult.rows.length);
    res.json({
      page: Number(page),
      count: postsResult.rows.length,
      posts: postsResult.rows
    });

  } catch (err) {
    console.error("Error en'/api/allPosts/users/feed/:", err.stack);
    res.status(500).json({ error: 'Error al obtener posts del feed' });
  }
});


// Enviar notificación cuando alguien sigue a otro usuario
app.use(notificationsRouter);
// Rutas para la funcionalidad de competencias
app.use(compete);
// Rutas para ver las competencias
app.use(onChallenge);

app.listen(PORT, () => {
  console.log(`Servidor escuchando en puerto ${PORT}`);
});

