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
    final         BOOLEAN NOT NULL DEFAULT FALSE   -- le trouver termine la partie
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
    code          CHAR(4) CHECK (code ~ '^[0-9]{4}$'),    -- bloqué par code : le code attendu
    CHECK ((id_debloquant IS NULL) <> (code IS NULL))     -- exactement l'un des deux
);

-- Scores du Hall of fame
CREATE TABLE score (
    id     SERIAL PRIMARY KEY,
    pseudo TEXT NOT NULL,
    points INTEGER NOT NULL,
    date   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Scénario d'exemple (à remplacer par le vrai scénario)
-- Icône par défaut de Leaflet : 25x41 px, pointe en (12, 41)
INSERT INTO objet (id, nom, type, geom, zoom_min, icone_url, icone_largeur, icone_hauteur, ancre_x, ancre_y, depart, final) VALUES
(1, 'Clé rouillée',     'recuperable',  ST_SetSRID(ST_MakePoint(2.3499, 48.8530), 4326), 14, 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png', 25, 41, 12, 41, TRUE,  FALSE),
(2, 'Coffre du Louvre', 'bloque_objet', ST_SetSRID(ST_MakePoint(2.3376, 48.8606), 4326), 14, 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png', 25, 41, 12, 41, TRUE,  FALSE),
(3, 'Parchemin',        'code',         ST_SetSRID(ST_MakePoint(2.3691, 48.8532), 4326), 15, 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png', 25, 41, 12, 41, FALSE, FALSE),
(4, 'Cadenas Eiffel',   'bloque_code',  ST_SetSRID(ST_MakePoint(2.2945, 48.8584), 4326), 14, 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png', 25, 41, 12, 41, TRUE,  FALSE),
(5, 'Trophée',          'recuperable',  ST_SetSRID(ST_MakePoint(2.3431, 48.8867), 4326), 15, 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png', 25, 41, 12, 41, FALSE, TRUE);
SELECT setval('objet_id_seq', (SELECT max(id) FROM objet));

INSERT INTO objet_code (id_objet, code) VALUES (3, '1789');

INSERT INTO objet_bloque (id_objet, indice, id_libere, id_debloquant, code) VALUES
(2, 'Ce coffre est fermé à clé. Cherche du côté de Notre-Dame.', 3, 1,    NULL),
(4, 'Une date révolutionnaire ouvre ce cadenas.',               5, NULL, '1789');
