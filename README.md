# mon-journal

Un dépôt qui s'écrit tout seul, pour voir comment GitHub Actions fonctionne.

## En une image

GitHub prête des ordinateurs. Gratuitement, à la demande, pour quelques
secondes.

Ce dépôt contient des **fiches de consigne**. Chaque fiche dit : « quand tel
événement arrive, prends un ordinateur, fais ceci, puis range ».

C'est tout. Le reste n'est que du détail.

## Ce qui se passe sans intervention

Une fois par heure, sans que personne ne touche à rien :

1. Un ordinateur s'allume quelque part dans un centre de données.
2. Il télécharge ce dossier.
3. Il ajoute **une ligne** dans `entrees/battements.md` : la date et l'heure.
4. Il renvoie le dossier à GitHub.
5. Il est détruit. Définitivement.

Une heure plus tard, un autre ordinateur — pas le même, il n'existait pas
encore — recommence.

Résultat : **un fichier qui s'allonge tout seul**.

Le passage a lieu **à la minute 17 de chaque heure**, en UTC. Pour le
déplacer, voir *Changer la fréquence des commits automatiques* plus bas.

## Les six boutons

Tous se lancent à la main depuis l'onglet **Actions** — y compris le 01, qui
tourne en plus tout seul. Appuyer, puis regarder ce qui se passe.

| Bouton | Ce qu'il fabrique | Où le résultat atterrit |
|---|---|---|
| **01 · Battement** | Une ligne horodatée | `entrees/battements.md` |
| **02 · Contexte** | Un rapport sur la machine qui exécute | `entrees/contexte.md` |
| **03 · Matrice** | N fichiers, écrits par N ordinateurs en parallèle | `fragments/fragment-1.md` … `fragment-N.md` |
| **04 · Domino** | Un commit, pour montrer qu'un robot n'en réveille pas un autre | `entrees/domino.md` |
| **04b · Écoute des push** | Un témoin, qui ne s'allume que pour un commit humain | **rien dans le dépôt** |
| **05 · Collision** | Trois ordinateurs qui rangent au même instant, et se bousculent | `entrees/collisions/voie-a.md`, `voie-b.md`, `voie-c.md` |

Trois précisions sur cette colonne de droite :

- **Les fichiers n'apparaissent sur le poste qu'après un `git pull`.** Ils sont
  écrits par une machine distante, qui les range dans le dépôt ; rien n'arrive
  localement tout seul.
- **`04b` est le seul à ne rien produire.** Sa sortie est le *résumé* affiché
  sur la page de son exécution, dans l'onglet Actions. Les cinq autres en
  écrivent un aussi, en complément de leurs fichiers.
- **Un fichier n'existe qu'une fois son bouton pressé au moins une fois.** Sur
  un dépôt fraîchement cloné, aucun de ces chemins n'est présent : ils
  apparaissent au fil des exécutions.

## À quoi ça sert ?

À rien. C'est volontaire.

Les fichiers produits ne contiennent que des horodatages. Aucune valeur, aucun
usage.

C'est une **maquette transparente**. Comme un moteur en plexiglas : il ne fait
avancer aucune voiture, mais on voit les pistons bouger. Ici on voit qui
déclenche quoi, avec quels droits, sur quelle machine, et ce qui casse quand
deux tâches se marchent dessus.

## Comment regarder

```bash
git pull && cat entrees/battements.md     # le fichier qui grandit tout seul
gh run list                               # ce qui s'est exécuté récemment
gh repo view --web                        # l'onglet Actions dans le navigateur
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

```yaml
on:
  schedule:
    - cron: "17 * * * *"
```

Ce réglage donne un passage par heure, **à la minute 17**, en UTC.

**GitHub Actions ne connaît que l'UTC**, et aucun réglage de fuseau n'existe.
Sans conséquence pour un réglage horaire comme celui-ci, mais décisif dès
qu'on vise une heure précise : `0 3 * * *` part à 5 h du matin heure de Paris
l'été, et 4 h l'hiver — le décalage bouge deux fois par an alors que le
fichier, lui, ne change pas.

Les cinq champs se lisent ainsi :

```
┌───────────── minute           (0-59)
│ ┌─────────── heure            (0-23, en UTC)
│ │ ┌───────── jour du mois     (1-31)
│ │ │ ┌─────── mois             (1-12)
│ │ │ │ ┌───── jour de semaine  (0-6, 0 = dimanche)
* * * * *
```

Quelques réglages courants :

| Pour... | Écrire |
|---|---|
| une fois par jour, à 03:00 UTC | `0 3 * * *` |
| toutes les heures | `17 * * * *` — minute décalée, réglage courant |
| toutes les 15 minutes | `*/15 * * * *` |
| en semaine seulement, à 09:00 UTC | `0 9 * * 1-5` |
| le 1ᵉʳ de chaque mois | `0 0 1 * *` |

Après modification, il faut commiter et pousser **sur la branche par défaut** :
un `schedule` posé sur une autre branche ne se déclenche jamais. La prise en
compte demande quelques minutes.

Trois limites à connaître :

- l'intervalle minimum accepté est de **5 minutes** ;
- l'heure demandée n'est qu'une intention, et l'écart réel est large — voir
  *Ce qui a cassé en route* ;
- une minute ronde (`0`, `30`) tombe dans l'embouteillage des crons calés sur
  l'heure ; une minute décalée comme `:17` est mieux servie.

---

# Le détail, pour creuser

Le reste de ce fichier s'adresse à qui veut comprendre la mécanique. Rien
au-dessus de cette ligne n'en dépend.

## La chose la plus contre-intuitive

**L'ordinateur qui a écrit la ligne d'hier n'existe plus.**

Il n'y a pas de serveur quelque part avec le projet dessus. Chaque exécution
est une machine neuve, née pour vingt secondes et détruite aussitôt. Rien ne
survit d'une exécution à l'autre — sauf ce qui a été rangé dans le dépôt.

C'est pour ça que chaque fiche se termine par un `git push`. Sans lui, le
travail disparaît avec la machine.

## Les six mécaniques

**01 · Battement — écrire dans son propre dépôt.** Une ligne horodatée à
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
  la seconde compte pour ça — voir la leçon 04.
- **L'attribution n'est pas une authentification.** N'importe qui peut inscrire
  n'importe quelle adresse dans un commit. Seule une signature cryptographique,
  qui donne le badge *Verified*, prouve quelque chose.
- Un workflow planifié tourne même quand rien n'a changé. Sans le
  `git diff --cached --quiet` de `scripts/pousser.sh`, `git commit` échouerait
  et ferait passer le run en rouge sans raison.

**02 · Contexte — voir ce que la machine sait d'elle-même.**

- Le contexte `github` **contient le jeton d'accès**. Masqué dans les journaux,
  pas dans un fichier commité. Le script filtre par **liste blanche** : seules
  des clés nommées une à une sortent. Une liste noire (`del(.token)`) laisserait
  passer tout ce qu'on n'a pas prévu — sur ce dépôt, 22 clés ont été écartées,
  dont `secret_source` qu'on n'aurait pas pensé à nommer.
- Certaines variables sont des **fichiers, pas des valeurs** : `GITHUB_ENV`,
  `GITHUB_OUTPUT`, `GITHUB_STEP_SUMMARY`. On y écrit une ligne pour parler à la
  suite du workflow.
- `${{ }}` est remplacé **avant** que bash ne voie la ligne. D'où le passage
  systématique par un bloc `env:`.

**03 · Matrice — plusieurs machines, un seul commit.**

- La taille d'une matrice **ne peut pas dépendre directement d'une entrée** :
  elle est figée à la lecture du fichier. Le détour : un premier job calcule la
  liste et la publie en JSON, le second la lit avec `fromJSON`.
- Les jobs **ne partagent aucun disque**. L'artefact est le seul canal pour
  faire descendre un fichier vers le job suivant.
- Les permissions se déclarent **au plus près** : le workflow part sur
  `permissions: {}`, chaque job élève ce dont il a besoin.
- `fail-fast: false` empêche l'échec d'une branche d'annuler les autres.

**04 · Domino — le push qui ne réveille personne.**

- Un push émis avec le jeton par défaut **ne déclenche aucun workflow**.
  Garde-fou anti-boucle infinie, non désactivable.
- Pour le lever : jeton personnel, clé de déploiement, ou GitHub App. La boucle
  infinie redevient alors possible, et il faut la bloquer explicitement.
- Vérification : un commit poussé depuis un poste déclenche `04b` ; un run de
  `04` ne le déclenche pas.

**05 · Collision — trois jobs qui poussent en même temps.**

- Le premier arrivé gagne, les autres sont refusés. La boucle de
  `scripts/pousser.sh` rebase et réessaie, avec une attente croissante.
- Observé sur ce dépôt : voie **b** passée du premier coup, voie **a** refusée
  une fois, voie **c** refusée **deux** fois — pendant qu'elle rebasait, une
  autre voie avait encore bougé la cible.
- Le rebase ne sauve que si les fichiers sont **disjoints**. Sur le même
  fichier, c'est un conflit que le script ne peut pas trancher : il s'arrête
  avec un message qui le dit.
- L'alternative est de ne pas paralléliser : un bloc `concurrency` sérialise
  les runs. Les workflows 01 à 04 partagent le groupe `journal` pour ça ; `05`
  s'en passe exprès.

## Ce qui a cassé en route

Trois enseignements viennent de bugs, pas du code prévu. Aucun n'était visible
au premier essai.

**L'artefact embarquait tout son dossier.** Écrit d'abord avec
`path: fragments/`. Comme chaque job fait un `checkout`, son dossier contenait
déjà les fichiers des runs précédents : les cinq artefacts embarquaient les
cinq fichiers, et la fusion les écrasait les uns par les autres. **Un seul
fragment sur cinq ressortait à jour.** Invisible au premier run, où le dossier
n'existait pas encore. Correction : téléverser le fichier, pas son dossier.

**Le nom d'hôte et le `machine-id` ne distinguent pas les runners.** Mesuré sur
cinq machines simultanées : `hostname` est commun à toute la flotte, et
`/etc/machine-id` est identique partout — il est gravé dans l'image disque dont
les VM sont clonées. Deux identifiants qu'on croirait uniques. Ce qui varie
vraiment : `RUNNER_NAME`, et l'uptime — cinq durées différentes relevées à la
même seconde ne peuvent pas sortir d'une seule machine.

**Le cron honore environ 5 % de ce qu'on lui demande.** Réglé sur
`*/5 * * * *` pendant 3 h 20, soit une quarantaine de créneaux, il s'est
déclenché **deux fois** — à 20:24 et 21:38, deux heures qui ne tombent sur
aucun créneau demandé. Les vingt premières minutes n'ont rien produit. Les
exécutions manquées sont **sautées, pas empilées**. Ne jamais bâtir sur un
`schedule` quoi que ce soit de sensible au temps.

## Ce qu'il faut savoir avant de le laisser tourner

**Le coût dépend de la visibilité du dépôt**, et d'elle seule. Le code est
identique dans les deux cas.

| Visibilité | Minutes Actions |
|---|---|
| **publique** | gratuites et illimitées sur les runners standard |
| **privée** | décomptées d'un quota mensuel — 2 000 sur un compte gratuit |

En privé, le piège n'est pas la durée mais l'arrondi : **chaque job est arrondi
à la minute supérieure, séparément**. Un job de quinze secondes coûte une
minute pleine, une matrice de huit branches en coûte huit. Seul le `01` tourne
sans intervention, une fois par heure, soit environ **720 minutes par mois :
36 % du quota**. Pour réduire, espacer le cron — voir *Changer la fréquence des
commits automatiques*.

La limite de dépense d'un compte gratuit est à **0 € par défaut** : quota
épuisé, les workflows cessent simplement de démarrer, aucune facture n'arrive.

Pour connaître la visibilité courante : `gh repo view --json visibility`.

**Les workflows planifiés finissent par être désactivés.** Après une longue
période sans activité humaine, GitHub coupe les crons et prévient par courriel.
Un clic sur *Enable workflow* les relance.

**L'historique va gonfler.** Vingt-quatre commits par jour, indéfiniment —
soit près de 9 000 par an. Sans conséquence technique à cette échelle, mais ce
n'est pas un dépôt qu'on garde propre.

## Changer de visibilité

Le dépôt a fait l'aller-retour public → privé → public, pour vérifier ce que la
bascule change. Réponse : **le coût, et rien d'autre.**

```bash
gh repo edit --visibility private     # ou public
```

Trois choses à savoir avant de basculer.

**1. Le code n'a rien à changer.** Les six workflows se comportent
identiquement dans les deux visibilités. Le filtrage du contexte du `02` est en
liste blanche, donc correct qu'il y ait ou non des lecteurs anonymes.

**2. Ce qui a été public le reste.** Les forks et les clones déjà faits
subsistent ; repasser en privé ne les rétracte pas, et les archives tierces non
plus. Tout ce qui entre dans un dépôt pendant une phase publique doit être tenu
pour publié définitivement — y compris l'adresse de courriel des auteurs de
commit, que `git log` expose et qu'aucun changement de visibilité ne retire.
C'est pourquoi les commits d'ici utilisent l'adresse `noreply` de GitHub.

**3. La facturation suit la visibilité**, voir le tableau plus haut.

Un point de vigilance permanent : **aucun workflow ne se déclenche sur
`pull_request`**. C'est ce qui empêche un fork d'exécuter quoi que ce soit ici
pendant les phases publiques. Si ce déclencheur est ajouté un jour, relire la
question de près — `pull_request_target` donne à du code venu d'un fork l'accès
aux secrets du dépôt.

## Les fichiers

```
.github/workflows/     les six fiches de consigne, une par mécanique
scripts/               la logique, sortie des blocs `run:`
entrees/               produit par les workflows — ne pas éditer à la main
fragments/             produit par le workflow 03
```

La logique vit dans `scripts/` plutôt que dans des blocs `run: |` pour deux
raisons : un heredoc dans un YAML indenté conserve son indentation et décale
tout ce qu'il écrit, et un script se teste depuis son poste sans consommer de
run.

```bash
bash -n scripts/*.sh
NUMERO=0 CTX_GITHUB='{"a":1}' CTX_RUNNER='{}' ./scripts/ecrire-contexte.sh
```

Un piège de syntaxe à connaître : un `: ` dans une valeur YAML non quotée est
lu comme un séparateur clé/valeur, et le fichier ne se charge plus. GitHub
n'affiche alors aucune erreur — le workflow **disparaît simplement** de la
liste. D'où les quotes simples autour des appels à `pousser.sh`.
