<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Escape game</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
    <style>
        body { margin: 0; font-family: system-ui, sans-serif; }
        #app { display: flex; height: 100vh; }
        #carte { flex: 1; }
        aside { width: 300px; padding: 1rem; overflow-y: auto; box-sizing: border-box; }
        .message { background: #f3f0e6; padding: .75rem; border-radius: 6px; }
        .inventaire { list-style: none; padding: 0; display: flex; flex-wrap: wrap; gap: .5rem; }
        .inventaire button { display: flex; flex-direction: column; align-items: center; padding: .4rem; border: 2px solid #ccc; border-radius: 6px; background: white; cursor: pointer; }
        .inventaire button.selectionne { border-color: #d35400; }
        .inventaire img { height: 32px; }
        @media (max-width: 700px) {
            #app { flex-direction: column; }
            aside { width: auto; height: 40vh; }
        }
    </style>
</head>
<body>
    <div id="app">
        <div id="carte"></div>
        <aside>
            <h1>Escape game</h1>
            <p class="message">{{ message }}</p>

            <form v-if="objetCode" @submit.prevent="verifierCode">
                <label>Code de {{ objetCode.nom }} :
                    <input v-model="codeSaisi" required autofocus>
                </label>
                <button>Valider</button>
            </form>

            <h2>Inventaire</h2>
            <p v-if="inventaire.length === 0">Vide.</p>
            <p v-else>Clique sur un objet pour le sélectionner, puis sur l'objet bloqué de la carte.</p>
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
    <script src="/js/jeu.js"></script>
</body>
</html>
