<?php

declare(strict_types=1);

require_once 'flight/Flight.php';

// Connexion PDO partagée : Flight::db() renvoie toujours la même instance.
// PDO (PHP >= 8.1) rend les int/bool/float PostgreSQL avec leur vrai type PHP, donc bien typés en JSON.
Flight::register('db', PDO::class, ['pgsql:host=db;port=5432;dbname=mydb', 'postgres', 'postgres', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]]);

// Requête commune aux routes objets : un objet + les champs de sa sous-classe (NULL sinon).
// Géométrie renvoyée en lon/lat numériques (directement utilisables par la carte).
// objet_code.code et objet_bloque.code ont le même nom : on renomme le second en code_attendu.
const SQL_OBJETS = "
    SELECT o.id, o.nom, o.type,
           ST_X(o.geom) AS lon, ST_Y(o.geom) AS lat,
           o.zoom_min, o.icone_url, o.icone_largeur, o.icone_hauteur, o.ancre_x, o.ancre_y,
           o.depart, o.final, o.message,
           c.code,
           b.indice, b.id_libere, b.id_debloquant, b.code AS code_attendu
    FROM objet o
    LEFT JOIN objet_code c ON c.id_objet = o.id
    LEFT JOIN objet_bloque b ON b.id_objet = o.id
";

// PDO sous PHP 8.2 rend les décimaux en texte : on convertit lon/lat en nombres
function typerObjet(array $objet): array {
    $objet['lon'] = (float) $objet['lon'];
    $objet['lat'] = (float) $objet['lat'];
    return $objet;
}

// GET api/objets : objets visibles au début de la partie
Flight::route('GET /api/objets', function () {
    $objets = Flight::db()->query(SQL_OBJETS . ' WHERE o.depart ORDER BY o.id')->fetchAll();
    Flight::json(array_map('typerObjet', $objets));
});

// GET api/objets/N : un objet (objet libéré, objet bloquant...)
Flight::route('GET /api/objets/@id:[0-9]+', function (string $id) {
    $requete = Flight::db()->prepare(SQL_OBJETS . ' WHERE o.id = ?');  // requête préparée : pas d'injection SQL
    $requete->execute([(int) $id]);
    $objet = $requete->fetch();
    if ($objet === false) {
        Flight::json(['erreur' => 'Objet introuvable'], 404);
        return;
    }
    Flight::json(typerObjet($objet));
});

// POST api/scores : enregistre un score { "pseudo": "...", "points": 1234 }
// Le score est calculé par le client : on vérifie seulement qu'il est plausible.
Flight::route('POST /api/scores', function () {
    $donnees = Flight::request()->data;
    $pseudo = trim((string) ($donnees->pseudo ?? ''));
    $points = $donnees->points ?? null;
    if ($pseudo === '' || mb_strlen($pseudo) > 30 || !is_int($points) || $points < 0 || $points > 10000) {
        Flight::json(['erreur' => 'Pseudo (1 à 30 caractères) et points (entier de 0 à 10000) requis'], 400);
        return;
    }
    $requete = Flight::db()->prepare('INSERT INTO score (pseudo, points) VALUES (?, ?) RETURNING id, pseudo, points, date');
    $requete->execute([$pseudo, $points]);
    Flight::json($requete->fetch(), 201);
});

Flight::route('/jeu', function () {
    Flight::render('jeu');
});

// Accueil avec le Hall of fame : 10 meilleurs scores (à égalité, le plus ancien d'abord)
Flight::route('/', function() {
    $scores = Flight::db()->query('SELECT pseudo, points, date FROM score ORDER BY points DESC, date LIMIT 10')->fetchAll();
    Flight::render('accueil', ['scores' => $scores]);
});

Flight::route('/test-db', function () {
    $host = 'db';
    $port = 5432;
    $dbname = 'mydb';
    $user = 'postgres';
    $pass = 'postgres';

    // Connexion BDD
    $link = pg_connect("host=$host port=$port dbname=$dbname user=$user password=$pass");

    $sql = "SELECT * FROM points";
    $query = pg_query($link, $sql);
    $results = pg_fetch_all($query);
    Flight::json($results);
});

Flight::start();

?>