# mon-journal

Un dépôt qui s'écrit tout seul, pour voir comment GitHub Actions fonctionne.

## En une image

GitHub prête des ordinateurs. Gratuitement, à la demande, pour quelques
secondes.

Ce dépôt contient des **fiches de consigne**. Chaque fiche dit : « quand tel
événement arrive, prends un ordinateur, fais ceci, puis range ».

C'est tout. Le reste n'est que du détail.

## Ce qui se passe sans intervention

Quatre fois par jour, sans que personne ne touche à rien :

1. Un ordinateur s'allume quelque part dans un centre de données.
2. Il télécharge ce dossier.
3. Il ajoute **une ligne** dans `entrees/battements.md` : la date et l'heure.
4. Il renvoie le dossier à GitHub.
5. Il est détruit. Définitivement.

Six heures plus tard, un autre ordinateur — pas le même, il n'existait pas
encore — recommence.

Résultat : **un fichier qui s'allonge tout seul**.

## Les cinq boutons

Le reste, ce sont des boutons dans l'onglet **Actions** : appuyer, puis
regarder ce qui se passe.

| Bouton | Ce qu'il fabrique |
|---|---|
| **02 · Contexte** | Un rapport : « voici la machine sur laquelle je tourne, voici ce que je sais » |
| **03 · Matrice** | Cinq fichiers, écrits par cinq ordinateurs différents en même temps |
| **04 · Domino** | Un commit, pour montrer qu'un robot ne réveille pas un autre robot |
| **04b** | Un témoin, qui ne s'allume que pour les commits venus d'un humain |
| **05 · Collision** | Trois ordinateurs qui rangent leur copie **au même instant**, et se bousculent |

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

**01 · Battement — écrire dans son propre dépôt.** Une ligne horodatée toutes
les six heures.

- Le jeton donné à un workflow est **en lecture seule**. Sans
  `permissions: contents: write`, le push part en 403. C'est l'erreur la plus
  fréquente.
- Le commit apparaît sous `github-actions[bot]`, pas sous un nom humain.
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

**Tant que le dépôt est public, les minutes sont gratuites et illimitées** sur
les runners standard. Rien à surveiller.

**Les workflows planifiés finissent par être désactivés.** Après une longue
période sans activité humaine, GitHub coupe les crons et prévient par courriel.
Un clic sur *Enable workflow* les relance.

**L'historique va gonfler.** Quatre commits par jour, indéfiniment. Sans
conséquence à cette échelle, mais ce n'est pas un dépôt qu'on garde propre.

## Le jour où il passera en privé

**1. La facturation démarre.** Quota mensuel — 2 000 minutes sur un compte
gratuit — et **chaque job est arrondi à la minute supérieure, séparément**. Un
job de quinze secondes coûte une minute pleine ; une matrice de huit branches
coûte huit minutes. Seul le 01 tourne seul : environ 120 minutes par mois. Le
commentaire au-dessus de son `cron:` rappelle comment l'espacer. La limite de
dépense d'un compte gratuit est à 0 € par défaut : quota épuisé, les workflows
cessent de démarrer, aucune facture n'arrive.

**2. Passer en privé n'efface pas ce qui a été public.** Les forks et les
clones déjà faits subsistent. Tout ce qui est entré dans le dépôt pendant la
phase publique doit être tenu pour publié définitivement — y compris l'adresse
de courriel des auteurs de commit, que `git log` expose. C'est pourquoi les
commits d'ici utilisent l'adresse `noreply` de GitHub.

**3. Le code n'a rien à changer.** Les six workflows se comportent
identiquement dans les deux visibilités.

Un point de vigilance tant que le dépôt est public : **aucun workflow ne se
déclenche sur `pull_request`**, et c'est ce qui empêche un fork d'exécuter quoi
que ce soit ici. Si ce déclencheur est ajouté un jour, relire la question de
près — `pull_request_target` donne à du code venu d'un fork l'accès aux secrets.

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
