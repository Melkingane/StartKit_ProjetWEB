// Escape game : logique du client (Vue 3 + Leaflet)
// Le scénario vient entièrement de l'API : ce code ne connaît aucun objet en dur.

const { createApp } = Vue;

createApp({
    // État affiché par Vue (réactif)
    data() {
        return {
            inventaire: [],      // objets récupérés (objets complets renvoyés par l'API)
            selection: null,     // id de l'objet d'inventaire sélectionné, ou null
            message: 'Zoome sur Paris pour découvrir les objets.',
            objetCode: null,     // objet bloqué par code dont le formulaire est ouvert
            codeSaisi: '',
            fini: false,
        };
    },

    // Création de la carte une fois le HTML en place, puis chargement des objets de départ.
    // carte et marqueurs ne sont pas dans data() : Leaflet ne doit pas être rendu réactif par Vue.
    mounted() {
        this.carte = L.map('carte').setView([48.8566, 2.3422], 13);
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap',
        }).addTo(this.carte);
        this.marqueurs = {};  // id objet -> { objet, marqueur }

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
                    this.message = `Tu as récupéré : ${objet.nom}.`;
                    if (objet.final) this.terminer();
                    break;

                // Code : affiche son code à 4 chiffres
                case 'code':
                    this.message = `${objet.nom} : le code est ${objet.code}.`;
                    break;

                // Bloqué par objet : s'ouvre si le bon objet est sélectionné dans l'inventaire, sinon indice
                case 'bloque_objet':
                    if (this.selection === objet.id_debloquant) {
                        this.inventaire = this.inventaire.filter(o => o.id !== this.selection);  // l'objet utilisé est consommé
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

        // Soumission du formulaire : vérifie le code saisi pour l'objet bloqué par code
        verifierCode() {
            if (this.codeSaisi === this.objetCode.code_attendu) {
                const objet = this.objetCode;
                this.objetCode = null;
                this.debloquer(objet);
            } else {
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
                    this.message = `${objet.nom} s'ouvre ! Un nouvel objet est apparu : ${libere.nom}.`;
                });
        },

        // Sélectionne / désélectionne un objet de l'inventaire (pour l'utiliser sur un objet bloqué)
        selectionner(objet) {
            this.selection = this.selection === objet.id ? null : objet.id;
        },

        // Fin de partie (le calcul et l'enregistrement du score viendront ici)
        terminer() {
            this.fini = true;
            this.message = 'Bravo, tu as trouvé l\'objet final !';
        },
    },
}).mount('#app');
