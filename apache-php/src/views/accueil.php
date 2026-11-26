<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>La recette de papi</title>
    <link rel="stylesheet" href="/css/style.css?v=<?= filemtime(__DIR__ . '/../css/style.css') ?>">
    <style>
        main { max-width: 640px; margin: 0 auto; padding: 3rem 1rem; }
        h1 { font-size: 3rem; }
        .note { margin: 2rem 0; }
        ol { line-height: 1.6; }
        .bouton { font-size: 1.3rem; padding: .6rem 1.6rem; transform: rotate(1deg); }
        .aide { font-size: .85rem; }
        .hall { font-family: var(--machine); padding-left: 1.5rem; }
        .hall li { border-bottom: 1px dashed var(--encre); padding: .3rem 0; }
        .hall b { float: right; }
    </style>
</head>
<body>
    <main>
        <h1>La recette de papi</h1>

        <div class="note">
            Le patron d'un pub irlandais part à la recherche de la recette de bière parfaite
            de son arrière-grand-père. Une seule piste : une lettre laissée par papi, quelque part à Dublin.
        </div>

        <h2>Comment jouer</h2>
        <ol>
            <li>Clique sur les objets de la carte. Zoome : certains n'apparaissent que de près.</li>
            <li>Les objets récupérés vont dans ton inventaire.</li>
            <li>Un objet bloqué s'ouvre avec le bon objet sélectionné dans l'inventaire, ou avec le bon code.</li>
            <li>Lis bien les messages : ils contiennent les indices.</li>
        </ol>

        <p><a class="bouton" href="/jeu">Jouer</a></p>

        <h2>Hall of fame</h2>
        <p class="aide">Score = 10 000 − 1 par seconde de jeu − 100 par mauvais code − 1 000 si la triche a été utilisée.</p>
        <?php if (!$scores): ?>
            <p>Aucun score pour l'instant. Sois le premier !</p>
        <?php else: ?>
            <ol class="hall">
                <?php foreach ($scores as $s): ?>
                    <!-- htmlspecialchars : un pseudo contenant du HTML s'affiche comme du texte -->
                    <li><span><?= htmlspecialchars($s['pseudo']) ?></span> <b><?= $s['points'] ?></b></li>
                <?php endforeach; ?>
            </ol>
        <?php endif; ?>
    </main>
</body>
</html>
