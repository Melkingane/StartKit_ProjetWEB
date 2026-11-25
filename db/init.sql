-- Activer PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- Table d'exemple du starter kit (utilisée par /test-db)
CREATE TABLE IF NOT EXISTS points (
    id SERIAL PRIMARY KEY,
    name TEXT,
    geom geometry(Point, 4326)
);

-- Rejouable : on repart de zéro
DROP TABLE IF EXISTS score, objet_bloque, objet_code, objet;

-- Objet (classe abstraite) : attributs communs à tous les objets
CREATE TABLE objet (
    id            SERIAL PRIMARY KEY,
    nom           TEXT NOT NULL,
    type          TEXT NOT NULL CHECK (type IN ('recuperable', 'code', 'bloque_objet', 'bloque_code')),
    geom          geometry(Point, 4326) NOT NULL,
    zoom_min      INTEGER NOT NULL DEFAULT 0,      -- visible à partir de ce niveau de zoom
    icone_url     TEXT NOT NULL,
    icone_largeur INTEGER NOT NULL,                -- taille en pixels
    icone_hauteur INTEGER NOT NULL,
    ancre_x       INTEGER NOT NULL,                -- point de l'icône posé sur la position
    ancre_y       INTEGER NOT NULL,
    depart        BOOLEAN NOT NULL DEFAULT FALSE,  -- affiché dès le début de la partie
    final         BOOLEAN NOT NULL DEFAULT FALSE,  -- le trouver termine la partie
    message       TEXT                             -- texte affiché au clic (récupérable, code) ou après déblocage
);

-- ObjetCode : affiche un code à 4 chiffres
CREATE TABLE objet_code (
    id_objet INTEGER PRIMARY KEY REFERENCES objet(id) ON DELETE CASCADE,
    code     CHAR(4) NOT NULL CHECK (code ~ '^[0-9]{4}$')
);

-- ObjetBloqueParObjet / ObjetBloqueParCode : même table, ils partagent indice et objet libéré
CREATE TABLE objet_bloque (
    id_objet      INTEGER PRIMARY KEY REFERENCES objet(id) ON DELETE CASCADE,
    indice        TEXT,
    id_libere     INTEGER NOT NULL REFERENCES objet(id),  -- objet qui apparaît une fois débloqué
    id_debloquant INTEGER REFERENCES objet(id),           -- bloqué par objet : l'objet d'inventaire attendu
    code          TEXT,                                   -- bloqué par code : la réponse attendue (chiffres ou texte)
    CHECK ((id_debloquant IS NULL) <> (code IS NULL))     -- exactement l'un des deux
);

-- Scores du Hall of fame
CREATE TABLE score (
    id     SERIAL PRIMARY KEY,
    pseudo TEXT NOT NULL,
    points INTEGER NOT NULL,
    date   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Scénario « La recette de papi » (voir scenario.md)
-- Icônes : Twemoji (CC-BY 4.0), 32x32 px, ancrées en leur centre (16, 16)
INSERT INTO objet (id, nom, type, geom, zoom_min, icone_url, icone_largeur, icone_hauteur, ancre_x, ancre_y, depart, final, message) VALUES
(1,  'Pub à Dublin (lettre de papi)',          'recuperable',  ST_SetSRID(ST_MakePoint(-6.26430, 53.34550), 4326), 4,  'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/2709.svg',  32, 32, 16, 16, TRUE,  FALSE,
 'Lettre de papi : « Rends-toi à la capitale du pays de la bière. » Un aigle est dessiné dessous. « Quand tout sera terminé, prends une photo de toi avec la tour Eiffel. »'),
(2,  'Contact à Berlin',                       'recuperable',  ST_SetSRID(ST_MakePoint(13.41320, 52.52190), 4326), 11, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f4c7.svg', 32, 32, 16, 16, TRUE,  FALSE,
 '« N''importe quoi, la meilleure bière c''est en Belgique ! Mon cousin de Bruxelles a ce que tu cherches. » Il te tend la carte de visite de son cousin.'),
(3,  'Cousin à Bruxelles',                     'bloque_objet', ST_SetSRID(ST_MakePoint(4.35170, 50.84670), 4326),  12, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f9d4.svg', 32, 32, 16, 16, TRUE,  FALSE,
 '« Ton carton d''invitation pour la fête du houblon ? Je l''ai confié à un ami, sous la cathédrale en choucroute. »'),
(4,  'Homme sous la cathédrale',               'bloque_code',  ST_SetSRID(ST_MakePoint(7.75090, 48.58180), 4326),  12, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/26ea.svg',  32, 32, 16, 16, FALSE, FALSE,
 '« Voici votre invitation. La fête, c''est à Haguenau. »'),
(5,  'Carton d''invitation',                   'recuperable',  ST_SetSRID(ST_MakePoint(7.75110, 48.58200), 4326),  12, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f48c.svg', 32, 32, 16, 16, FALSE, FALSE,
 'Carton d''invitation à la fête du houblon.'),
(6,  'Fête du houblon (Haguenau)',             'bloque_objet', ST_SetSRID(ST_MakePoint(7.78949, 48.81427), 4326),  14, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f37b.svg', 32, 32, 16, 16, TRUE,  FALSE,
 'Le code a été volé ! Le voleur « parlait de Mickey » et a laissé tomber son billet. Récupérez-le.'),
(7,  'Billet du voleur',                       'recuperable',  ST_SetSRID(ST_MakePoint(7.78969, 48.81447), 4326),  14, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f3ab.svg', 32, 32, 16, 16, FALSE, FALSE,
 'Billet de train Haguenau → Marne-la-Vallée–Chessy.'),
(8,  'Le voleur (gare Marne-la-Vallée–Chessy)', 'bloque_objet', ST_SetSRID(ST_MakePoint(2.78260, 48.86980), 4326),  14, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f9b9.svg', 32, 32, 16, 16, TRUE,  FALSE,
 'Voleur intercepté ! Il a laissé tomber une carte chiffrée…'),
(9,  'Carte chiffrée',                         'recuperable',  ST_SetSRID(ST_MakePoint(2.78280, 48.87000), 4326),  14, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f5fa.svg', 32, 32, 16, 16, FALSE, FALSE,
 'Carte chiffrée : il faut des géomaticiens pour la lire. Si seulement on connaissait un endroit où il y en a plein…'),
(10, 'École Géodata Paris',                    'bloque_objet', ST_SetSRID(ST_MakePoint(2.58730, 48.84100), 4326),  15, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f393.svg', 32, 32, 16, 16, TRUE,  FALSE,
 'Carte déchiffrée : une image de marais avec PARIS écrit en gros dessus.'),
(11, 'Point dans le Marais',                   'code',         ST_SetSRID(ST_MakePoint(2.36550, 48.85560), 4326),  15, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f4f0.svg', 32, 32, 16, 16, FALSE, FALSE,
 'Journal d''époque sur la loi de pureté de la bière : datant de 1516. « Pour fêter la trouvaille de ce code, comme papi vous l''avez demandé allez prendre une photo sur la tour Eiffel. »'),
(12, 'Tour Eiffel',                            'bloque_objet', ST_SetSRID(ST_MakePoint(2.29450, 48.85840), 4326),  15, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f4f7.svg', 32, 32, 16, 16, TRUE,  FALSE,
 'Photo prise pour papi ! Direction le pub.'),
(13, 'Coffre de papi (pub à Dublin)',          'bloque_code',  ST_SetSRID(ST_MakePoint(-6.26420, 53.34560), 4326), 8, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f512.svg', 32, 32, 16, 16, FALSE, FALSE,
 'La recette est détenue depuis toutes ces années par les maîtres brasseurs du Viaduc Café. Direction le 12e arrondissement !'),
(14, 'Viaduc Café (av. Daumesnil, Paris 12e)', 'recuperable',  ST_SetSRID(ST_MakePoint(2.37300, 48.84700), 4326),  14, 'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.1.0/assets/svg/1f37a.svg', 32, 32, 16, 16, FALSE, TRUE,
 'Un dernier verre chez le vieil ami de papi : on siffle le tonneau !');
SELECT setval('objet_id_seq', (SELECT max(id) FROM objet));

INSERT INTO objet_code (id_objet, code) VALUES (11, '1516');

INSERT INTO objet_bloque (id_objet, indice, id_libere, id_debloquant, code) VALUES
(3,  'Je ne reçois que sur recommandation.',                        4,  2,    NULL),
(4,  '« Big Brother is watching you. » De quelle œuvre vient cette phrase ?', 5, NULL, '1984'),
(6,  'Entrée sur invitation.',                                      7,  5,    NULL),
(8,  'Lequel est le voleur ? Il faudrait une preuve de son trajet.', 9,  7,    NULL),
(10, 'Apportez-nous la carte à déchiffrer.',                        11, 9,    NULL),
(12, 'Papi voulait une photo…',                                     13, 1,    NULL),
(13, 'Il vous faut le code confié au contact.',                     14, NULL, '1516');
