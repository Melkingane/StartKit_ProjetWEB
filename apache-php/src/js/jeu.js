// Escape game : logique du client (Vue 3 + Leaflet)
// Le scénario vient entièrement de l'API : ce code ne connaît aucun objet en dur.

const { createApp } = Vue;

createApp({
    // État affiché par Vue (réactif)
    data() {
        return {
            inventaire: [],      // objets récupérés (objets complets renvoyés par l'API)
            selection: null,     // id de l'objet d'inventaire sélectionné, ou null
            message: 'Clique sur les objets de la carte. Zoome pour en découvrir d\'autres.',
            objetCode: null,     // objet bloqué par code dont le formulaire est ouvert
            codeSaisi: '',
            fini: false,
            triche: false,       // case « tricher » cochée ?
            aTriche: false,      // la triche a-t-elle été utilisée au moins une fois ? (pénalité)
            erreurs: 0,          // nombre de mauvais codes saisis (pénalité)
            score: null,         // calculé à la fin de la partie
            pseudo: '',
            scoreEnregistre: false,
        };
    },

    // Case « tricher » : affiche / masque la heatmap GeoServer, et retient qu'elle a servi
    watch: {
        triche(active) {
            if (active) {
                this.heatmap.addTo(this.carte);
                this.aTriche = true;
            } else {
                this.heatmap.remove();
            }
        },
    },

    // Création de la carte une fois le HTML en place, puis chargement des objets de départ.
    // carte et marqueurs ne sont pas dans data() : Leaflet ne doit pas être rendu réactif par Vue.
    mounted() {
        this.carte = L.map('carte').setView([50, 5], 5);  // vue sur l'Europe de l'Ouest
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap',
        }).addTo(this.carte);
        this.marqueurs = {};  // id objet -> { objet, marqueur }
        this.debut = Date.now();  // début de la partie, pour le score

        // Heatmap de tous les objets, servie en WMS par GeoServer (couche escape:objet, style heatmap).
        // Créée ici mais ajoutée à la carte seulement quand la case « tricher » est cochée.
        // pane overlayPane : au-dessus du fond de carte et hors du filtre sépia appliqué aux tuiles.
        this.heatmap = L.tileLayer.wms(`${location.protocol}//${location.hostname}:8080/geoserver/escape/wms`, {
            layers: 'escape:objet',
            format: 'image/png',
            transparent: true,
            pane: 'overlayPane',
        });

        // À chaque changement de zoom, on montre/cache les objets selon leur zoom minimal
        this.carte.on('zoomend', () => this.majVisibilite());

        fetch('/api/objets')
            .then(reponse => reponse.json())
            .then(objets => objets.forEach(objet => this.ajouterObjet(objet)));
    },

    methods: {
        // Crée le marqueur d'un objet avec son icône (url, taille, ancre) et le rend cliquable
        ajouterObjet(objet) {
            const icone = L.icon({
                iconUrl: objet.icone_url,
                iconSize: [objet.icone_largeur, objet.icone_hauteur],
                iconAnchor: [objet.ancre_x, objet.ancre_y],
            });
            const marqueur = L.marker([objet.lat, objet.lon], { icon: icone, title: objet.nom });
            marqueur.on('click', () => this.cliquerObjet(objet));
            this.marqueurs[objet.id] = { objet, marqueur };
            this.majVisibilite();
        },

        // Retire définitivement un objet de la carte (récupéré ou débloqué)
        retirerObjet(objet) {
            this.marqueurs[objet.id].marqueur.remove();
            delete this.marqueurs[objet.id];
        },

        // Affiche un objet seulement si le zoom actuel atteint son zoom minimal
        majVisibilite() {
            const zoom = this.carte.getZoom();
            for (const { objet, marqueur } of Object.values(this.marqueurs)) {
                if (zoom >= objet.zoom_min) marqueur.addTo(this.carte);
                else marqueur.remove();
            }
        },

        // Clic sur un objet de la carte : action selon son type
        cliquerObjet(objet) {
            this.objetCode = null;
            switch (objet.type) {
                // Récupérable : passe dans l'inventaire et quitte la carte ; l'objet final termine la partie
                case 'recuperable':
                    this.retirerObjet(objet);
                    this.inventaire.push(objet);
                    this.message = objet.message ?? `Tu as récupéré : ${objet.nom}.`;
                    if (objet.final) this.terminer();
                    break;

                // Code : affiche son message et son code à 4 chiffres
                case 'code':
                    this.message = `${objet.message ?? objet.nom} Code : ${objet.code}`;
                    break;

                // Bloqué par objet : s'ouvre si le bon objet est sélectionné dans l'inventaire, sinon indice.
                // L'objet utilisé reste dans l'inventaire (il peut resservir).
                case 'bloque_objet':
                    if (this.selection === objet.id_debloquant) {
                        this.selection = null;
                        this.debloquer(objet);
                    } else {
                        this.message = `${objet.nom} est bloqué. Indice : ${objet.indice}`;
                    }
                    break;

                // Bloqué par code : ouvre le formulaire de saisie du code
                case 'bloque_code':
                    this.objetCode = objet;
                    this.codeSaisi = '';
                    this.message = `${objet.nom} est verrouillé par un code. Indice : ${objet.indice}`;
                    break;
            }
        },

        // Met une réponse sous forme comparable : minuscules, sans espaces en trop ("  Elle  est BONNE " -> "elle est bonne")
        normaliser(texte) {
            return texte.trim().replace(/\s+/g, ' ').toLowerCase();
        },

        // Soumission du formulaire : vérifie la réponse saisie pour l'objet bloqué par code
        verifierCode() {
            if (this.normaliser(this.codeSaisi) === this.normaliser(this.objetCode.code_attendu)) {
                const objet = this.objetCode;
                this.objetCode = null;
                this.debloquer(objet);
            } else {
                this.erreurs++;
                this.message = `Mauvais code. Indice : ${this.objetCode.indice}`;
            }
        },

        // Débloque un objet : il disparaît et l'objet qu'il libère est demandé à l'API puis posé sur la carte
        debloquer(objet) {
            this.retirerObjet(objet);
            fetch(`/api/objets/${objet.id_libere}`)
                .then(reponse => reponse.json())
                .then(libere => {
                    this.ajouterObjet(libere);
                    this.message = objet.message ?? `${objet.nom} s'ouvre ! Un nouvel objet est apparu : ${libere.nom}.`;
                });
        },

        // Sélectionne / désélectionne un objet de l'inventaire (pour l'utiliser sur un objet bloqué)
        selectionner(objet) {
            this.selection = this.selection === objet.id ? null : objet.id;
        },

        // Fin de partie : calcul du score
        // score = 10 000 − 1 par seconde − 100 par mauvais code − 1 000 si triche utilisée (minimum 0)
        terminer() {
            const secondes = Math.round((Date.now() - this.debut) / 1000);
            this.score = Math.max(0, 10000 - secondes - 100 * this.erreurs - (this.aTriche ? 1000 : 0));
            this.fini = true;
            this.message += ` Bravo, tu as terminé la partie en ${Math.floor(secondes / 60)} min ${secondes % 60} s !`;
        },

        // Envoie le pseudo et le score à l'API pour le Hall of fame
        enregistrerScore() {
            fetch('/api/scores', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ pseudo: this.pseudo, points: this.score }),
            }).then(reponse => {
                if (reponse.ok) this.scoreEnregistre = true;
                else this.message = 'Le score n\'a pas pu être enregistré.';
            });
        },
    },
}).mount('#app');
