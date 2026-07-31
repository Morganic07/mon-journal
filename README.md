# mon-journal

Un dépôt qui s'écrit tout seul, pour voir comment GitHub Actions fonctionne.

A quoi ça sert ? À rien. C'est volontaire. Les fichiers produits ne contiennent que des horodatages. 



## En une image

GitHub prête des ordinateurs. Gratuitement, à la demande, pour quelques
secondes.

Ce dépôt contient des **fiches de consigne**. Chaque fiche dit : « quand tel
événement arrive, prends un ordinateur, fais ceci, puis range ».


## Ce qui se passe sans intervention

Une fois par heure, sans que personne ne touche à rien :

1. Un ordinateur s'allume quelque part dans un centre de données.
2. Il télécharge ce dossier.
3. Il ajoute **une ligne** dans `entrees/battements.md` : la date et l'heure.
4. Il renvoie le dossier à GitHub.
5. Il est détruit. Définitivement.


## Les six boutons

Tous se lancent à la main depuis l'onglet **Actions** y compris le 01, qui
tourne en plus tout seul. Appuyer, puis regarder ce qui se passe.

| Bouton | Ce qu'il fabrique | Où le résultat atterrit |
|---|---|---|
| **01 · Battement** | Une ligne horodatée | `entrees/battements.md` |
| **02 · Contexte** | Un rapport sur la machine qui exécute | `entrees/contexte.md` |
| **03 · Matrice** | N fichiers, écrits par N ordinateurs en parallèle | `fragments/fragment-1.md` … `fragment-N.md` |
| **04 · Domino** | Un commit, pour montrer qu'un robot n'en réveille pas un autre | `entrees/domino.md` |
| **04b · Écoute des push** | Un témoin, qui ne s'allume que pour un commit humain | **rien dans le dépôt** |
| **05 · Collision** | Trois ordinateurs qui rangent au même instant, et se bousculent | `entrees/collisions/voie-a.md`, `voie-b.md`, `voie-c.md` |


- **`04b` est le seul à ne rien produire.** Sa sortie est le *résumé* affiché
 sur la page de son exécution, dans l'onglet Actions. Les cinq autres en
 écrivent un aussi, en complément de leurs fichiers.


## Comment regarder

```bash
git pull && cat entrees/battements.md   # le fichier qui grandit tout seul
gh run list                # ce qui s'est exécuté récemment
gh repo view --web            # l'onglet Actions dans le navigateur
```

Pour appuyer sur un bouton :

```bash
gh workflow run "02 · Contexte"
```

**Pour tout arrêter :** onglet Actions, choisir un workflow à gauche, menu `...`
→ *Disable workflow*. Le dépôt reste consultable.


## Changer la fréquence des commits automatiques

Les commits automatiques viennent du workflow `01 · Battement`. Leur horaire
tient dans une seule ligne, au début de
`.github/workflows/01-battement.yml` :

Les cinq champs se lisent ainsi :

```
┌───────────── minute      (0-59)
│ ┌─────────── heure      (0-23, en UTC)
│ │ ┌───────── jour du mois   (1-31)
│ │ │ ┌─────── mois       (1-12)
│ │ │ │ ┌───── jour de semaine (0-6, 0 = dimanche)
* * * * *
```

Trois limites à connaître :

- l'intervalle minimum accepté est de **5 minutes** ;
- l'heure demandée n'est qu'une intention, et l'écart réel est large voir
 *Ce qui a cassé en route* ;
- une minute ronde (`0`, `30`) tombe dans l'embouteillage des crons calés sur
 l'heure ; une minute décalée comme `:17` est mieux servie.

---

## Ce qu'il faut savoir avant de le laisser tourner

**Le coût dépend de la visibilité du dépôt**, et d'elle seule. Le code est
identique dans les deux cas.

| Visibilité | Minutes Actions |
|---|---|
| **publique** | gratuites et illimitées sur les runners standard |
| **privée** | décomptées d'un quota mensuel 2 000 sur un compte gratuit |


**Les workflows planifiés finissent par être désactivés.** Après une longue
période sans activité humaine, GitHub coupe les crons et prévient par courriel.
Un clic sur *Enable workflow* les relance.

## Changer de visibilité

```bash
gh repo edit --visibility private   # ou public
```

**La facturation suit la visibilité**


## Les fichiers

```
.github/workflows/   les six fiches de consigne, une par mécanique
scripts/        la logique, sortie des blocs `run:`
entrees/        produit par les workflows ne pas éditer à la main
fragments/       produit par le workflow 03
```



## Les six mécaniques

**01 · Battement écrire dans son propre dépôt.** Une ligne horodatée à
chaque heure.

- Le jeton donné à un workflow est **en lecture seule**. Sans
 `permissions: contents: write`, le push part en 403. C'est l'erreur la plus
 fréquente.
- **L'auteur d'un commit se choisit.** GitHub rattache un commit à un compte
 par la seule adresse de courriel de l'auteur. `scripts/pousser.sh` inscrit
 celle du compte propriétaire, donc les commits automatiques portent son
 avatar et comptent dans son graphe de contributions. Y mettre
 `41898282+github-actions[bot]@users.noreply.github.com` les ferait repasser
 sous le robot intégré.
- **Auteur du commit et émetteur du push sont deux identités distinctes.**
 Changer la première ne change rien aux déclenchements : le push reste émis
 avec le jeton du workflow, donc il ne réveille aucun autre workflow. Seule
 la seconde compte pour ça voir la leçon 04.
- **L'attribution n'est pas une authentification.** N'importe qui peut inscrire
 n'importe quelle adresse dans un commit. Seule une signature cryptographique,
 qui donne le badge *Verified*, prouve quelque chose.
- Un workflow planifié tourne même quand rien n'a changé. Sans le
 `git diff --cached --quiet` de `scripts/pousser.sh`, `git commit` échouerait
 et ferait passer le run en rouge sans raison.

**02 · Contexte voir ce que la machine sait d'elle-même.**

- Le contexte `github` **contient le jeton d'accès**. Masqué dans les journaux,
 pas dans un fichier commité. Le script filtre par **liste blanche** : seules
 des clés nommées une à une sortent. Une liste noire (`del(.token)`) laisserait
 passer tout ce qu'on n'a pas prévu sur ce dépôt, 22 clés ont été écartées,
 dont `secret_source` qu'on n'aurait pas pensé à nommer.
- Certaines variables sont des **fichiers, pas des valeurs** : `GITHUB_ENV`,
 `GITHUB_OUTPUT`, `GITHUB_STEP_SUMMARY`. On y écrit une ligne pour parler à la
 suite du workflow.
- `${{ }}` est remplacé **avant** que bash ne voie la ligne. D'où le passage
 systématique par un bloc `env:`.

**03 · Matrice plusieurs machines, un seul commit.**

- La taille d'une matrice **ne peut pas dépendre directement d'une entrée** :
 elle est figée à la lecture du fichier. Le détour : un premier job calcule la
 liste et la publie en JSON, le second la lit avec `fromJSON`.
- Les jobs **ne partagent aucun disque**. L'artefact est le seul canal pour
 faire descendre un fichier vers le job suivant.
- Les permissions se déclarent **au plus près** : le workflow part sur
 `permissions: {}`, chaque job élève ce dont il a besoin.
- `fail-fast: false` empêche l'échec d'une branche d'annuler les autres.

**04 · Domino le push qui ne réveille personne.**

- Un push émis avec le jeton par défaut **ne déclenche aucun workflow**.
 Garde-fou anti-boucle infinie, non désactivable.
- Pour le lever : jeton personnel, clé de déploiement, ou GitHub App. La boucle
 infinie redevient alors possible, et il faut la bloquer explicitement.
- Vérification : un commit poussé depuis un poste déclenche `04b` ; un run de
 `04` ne le déclenche pas.

**05 · Collision trois jobs qui poussent en même temps.**

- Le premier arrivé gagne, les autres sont refusés. La boucle de
 `scripts/pousser.sh` rebase et réessaie, avec une attente croissante.
- Observé sur ce dépôt : voie **b** passée du premier coup, voie **a** refusée
 une fois, voie **c** refusée **deux** fois pendant qu'elle rebasait, une
 autre voie avait encore bougé la cible.
- Le rebase ne sauve que si les fichiers sont **disjoints**. Sur le même
 fichier, c'est un conflit que le script ne peut pas trancher : il s'arrête
 avec un message qui le dit.
- L'alternative est de ne pas paralléliser : un bloc `concurrency` sérialise
 les runs. Les workflows 01 à 04 partagent le groupe `journal` pour ça ; `05`
 s'en passe exprès.


