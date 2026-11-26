<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>La recette de papi</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
    <link rel="stylesheet" href="/css/style.css?v=<?= filemtime(__DIR__ . '/../css/style.css') ?>">
    <style>
        #app { display: flex; height: 100vh; }
        #carte { flex: 1; border-right: 2px solid var(--encre); }
        .leaflet-tile-pane { filter: sepia(.2) saturate(.9); }  /* fond de carte vieilli, marqueurs intacts */
        aside { width: 320px; padding: 1.5rem 1.2rem; overflow-y: auto; }
        h1 a { text-decoration: none; }
        form { margin-top: 1.2rem; display: flex; flex-wrap: wrap; gap: .5rem; align-items: end; }
        form label { width: 100%; font-family: var(--machine); }
        form input { flex: 1; min-width: 0; }

        /* Inventaire : chaque objet est un petit ticket penché ; le sélectionné se redresse et passe en rose */
        .inventaire { list-style: none; padding: 0; display: flex; flex-wrap: wrap; gap: .6rem; }
        .inventaire button { display: flex; flex-direction: column; align-items: center; gap: .3rem; width: 130px; font-size: .8rem; border-style: dashed; }
        .inventaire li:nth-child(odd) button { transform: rotate(-2deg); }
        .inventaire li:nth-child(even) button { transform: rotate(2deg); }
        .inventaire button.selectionne { transform: none; border: 3px solid var(--rose); background: #FFFDF6; color: var(--encre); }
        .inventaire img { height: 32px; }
        .aide { font-size: .85rem; }

        @media (max-width: 700px) {
            #app { flex-direction: column; }
            #carte { border-right: 0; border-bottom: 2px solid var(--encre); }
            aside { width: auto; height: 45vh; }
        }
    </style>
</head>
<body>
    <div id="app">
        <div id="carte"></div>
        <aside>
            <h1><a href="/">La recette de papi</a></h1>
            <div class="note" aria-live="polite">{{ message }}</div>

            <template v-if="fini">
                <h2>Score : {{ score }}</h2>
                <p class="aide">10 000 − {{ erreurs }} mauvais code(s) × 100 − le temps en secondes<span v-if="aTriche"> − 1 000 (triche)</span></p>
                <form v-if="!scoreEnregistre" @submit.prevent="enregistrerScore">
                    <label for="pseudo">Ton pseudo pour le Hall of fame :</label>
                    <input id="pseudo" v-model="pseudo" maxlength="30" required>
                    <button>Enregistrer</button>
                </form>
                <p v-else>Score enregistré ! <a href="/">Voir le Hall of fame</a></p>
            </template>

            <form v-if="objetCode" @submit.prevent="verifierCode">
                <label for="code">Code de {{ objetCode.nom }} :</label>
                <input id="code" v-model="codeSaisi" required autofocus>
                <button>Valider</button>
            </form>

            <p class="aide"><label><input type="checkbox" v-model="triche"> Tricher (afficher où sont les objets)</label></p>

            <h2>Inventaire</h2>
            <p class="aide" v-if="inventaire.length === 0">Vide.</p>
            <p class="aide" v-else>Clique sur un objet pour le sélectionner, puis sur l'objet bloqué de la carte.</p>
            <ul class="inventaire">
                <li v-for="objet in inventaire" :key="objet.id">
                    <button :class="{ selectionne: selection === objet.id }" @click="selectionner(objet)">
                        <img :src="objet.icone_url" alt="">
                        {{ objet.nom }}
                    </button>
                </li>
            </ul>
        </aside>
    </div>

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="https://unpkg.com/vue@3.5.13/dist/vue.global.prod.js"></script>
    <!-- ?v=date de modification : le navigateur recharge le fichier dès qu'il change -->
    <script src="/js/jeu.js?v=<?= filemtime(__DIR__ . '/../js/jeu.js') ?>"></script>
</body>
</html>
