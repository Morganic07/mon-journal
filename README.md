# mon-journal

Un dépôt qui s'écrit tout seul, pour regarder GitHub Actions fonctionner de
l'intérieur.

Le contenu produit n'a aucun intérêt : des horodatages, des fragments
numérotés. Ce qu'on observe, c'est la plomberie — qui déclenche quoi, avec
quels droits, sur quelle machine, et ce qui se passe quand deux jobs se
marchent dessus.

Six workflows, six mécaniques isolées. Chacun se lance à la main depuis
l'onglet **Actions**, sauf le premier qui tourne aussi tout seul.

---

## Mise en route

Les workflows doivent vivre sur la branche par défaut : un `on: schedule` posé
sur une autre branche ne se déclenche jamais.

```bash
gh repo create mon-journal --public --source=. --remote=origin --push
```

Puis, une seule fois, dans **Settings → Actions → General** :

- **Workflow permissions** : le bloc `permissions:` de chaque workflow demande
  explicitement ce dont il a besoin, donc le réglage par défaut peut rester sur
  *Read repository contents permission*. Si un push échoue malgré tout en
  **403**, c'est ici qu'il faut regarder — sur un dépôt appartenant à une
  organisation, un réglage supérieur peut plafonner ce qu'un workflow a le
  droit de demander.

Lancer ensuite **01 · Battement** à la main pour vérifier que la chaîne
complète passe.

---

## Les six leçons

### 01 · Battement — écrire dans son propre dépôt

Ajoute une ligne horodatée à `entrees/battements.md`, toutes les six heures et
sur demande.

À observer : le commit apparaît sous l'identité `github-actions[bot]`, pas sous
la tienne.

Ce que ça apprend :

- **Le jeton d'un workflow est en lecture seule.** Sans `permissions: contents:
  write`, le push part en 403. C'est l'erreur la plus fréquente des workflows
  qui écrivent.
- **Un workflow planifié tourne même quand rien n'a changé.** Sans le
  `git diff --cached --quiet` de `scripts/pousser.sh`, `git commit` échouerait
  et ferait passer le run en rouge sans raison.
- **Le cron n'est pas une horloge.** Des retards de dix à quarante minutes sont
  normaux, et des exécutions sont purement sautées en période de charge. La
  minute `:17` est choisie pour éviter l'embouteillage des crons calés sur
  l'heure ronde.

### 02 · Contexte — voir ce que le runner connaît

Écrit `entrees/contexte.md` : les contextes `github` et `runner` sérialisés, et
les caractéristiques de la machine.

Ce que ça apprend :

- **Le contexte `github` contient le jeton d'accès.** GitHub le masque dans les
  journaux, mais rien ne le masquerait dans un fichier commité. Le script le
  retire avec `jq 'del(.token, .event)'` *avant* la première écriture disque.
  Un `toJSON(github)` versionné brut est une fuite d'identifiants.
- **Certaines variables sont des fichiers, pas des valeurs.** `GITHUB_ENV`,
  `GITHUB_OUTPUT`, `GITHUB_STEP_SUMMARY`, `GITHUB_PATH` : on y écrit une ligne
  pour parler à la suite du workflow.
- **`${{ }}` est substitué avant bash.** D'où le passage systématique par un
  bloc `env:` plutôt qu'une interpolation directe dans le script.

### 03 · Matrice et artefacts — plusieurs machines, un seul commit

Demande un nombre de fragments (1 à 8), les génère en parallèle, puis les
rassemble et les commite en un seul passage.

Ce que ça apprend :

- **La taille d'une matrice ne peut pas dépendre directement d'une entrée.**
  Elle est figée à l'analyse du fichier. Le détour : un premier job calcule la
  liste et la publie en JSON dans `GITHUB_OUTPUT`, le second la lit avec
  `fromJSON`.
- **Les jobs ne partagent aucun disque.** Chaque branche de matrice tourne sur
  une machine neuve. L'artefact est le seul canal pour faire descendre un
  fichier vers le job suivant.
- **Un artefact téléverse ce qu'on lui donne, y compris ce qu'on n'a pas
  produit.** Ce workflow a d'abord été écrit avec `path: fragments/`. Comme
  chaque job fait un `checkout`, son dossier `fragments/` contenait déjà les
  fichiers des runs précédents : les cinq artefacts embarquaient les cinq
  fichiers, et le `merge-multiple` du job de rassemblement les écrasait les uns
  par les autres. Un seul fragment sur cinq ressortait à jour. Le premier run
  n'a rien montré — le dossier n'existait pas encore dans le dépôt. Téléverser
  le fichier, pas son dossier.
- **Le nom d'hôte ne distingue pas les runners.** Les machines d'un même run le
  partagent. Ce qui diffère réellement, et que les fragments relèvent : le
  runner alloué, l'identifiant machine, et l'uptime.
- **Les permissions se déclarent au plus près.** Le workflow part sur
  `permissions: {}`, le job de génération prend `contents: read`, seul le job
  de rassemblement obtient `contents: write`.
- **`fail-fast: false`** empêche l'échec d'une branche d'annuler les autres.

### 04 · Domino — le push qui ne réveille personne

`04` pousse un commit. `04b` écoute les push. Lancer `04`, puis regarder
l'onglet Actions : **aucun run de `04b` n'apparaît**.

Ce que ça apprend :

- **Un push émis avec le jeton par défaut ne déclenche aucun workflow.** Le
  garde-fou est là pour empêcher les boucles infinies, il n'est pas
  désactivable, et il surprend systématiquement quand on veut chaîner deux
  automatisations.
- Pour le lever, il faut d'autres identifiants — jeton personnel à portée
  restreinte, clé de déploiement, ou GitHub App. Avec eux, la boucle infinie
  redevient possible : c'est alors à toi de poser un garde-fou, par exemple un
  `if: github.actor != 'mon-bot'`.
- La voie sobre, quand on veut juste enchaîner : appeler explicitement le
  workflow suivant, avec `workflow_call` ou un `workflow_dispatch` déclenché
  par l'API.

Pour vérifier que `04b` n'est pas simplement cassé, pousser un commit à la main
depuis ton poste : là, il se déclenche.

### 05 · Collision — trois jobs qui poussent en même temps

Trois branches de matrice clonent le même commit, écrivent chacune dans son
fichier, et poussent simultanément.

Ce que ça apprend :

- **Le premier arrivé gagne, les autres sont refusés.** Ce n'est pas une
  erreur : la branche distante a bougé sous leurs pieds. La boucle de
  `scripts/pousser.sh` rebase et réessaie, avec une attente croissante.
- **Le rebase ne sauve que si les fichiers sont disjoints.** Si les trois voies
  ajoutaient des lignes au même fichier, le rebase tomberait sur un conflit que
  le script ne peut pas trancher — il s'arrête alors avec un message qui le
  dit.
- **L'alternative est de ne pas paralléliser.** Un bloc `concurrency` sérialise
  les runs, au prix de l'attente. Les workflows 01 à 04 utilisent tous le même
  groupe `journal` pour cette raison ; `05` s'en passe exprès.
- La collision n'est pas garantie à chaque exécution : si une voie termine
  avant que les autres n'aient poussé, tout passe du premier coup. Relancer.

---

## Ce qu'il faut savoir avant de le laisser tourner

**Tant que le dépôt est public, les minutes Actions sont gratuites et
illimitées** sur les runners standard. Rien à surveiller.

**Les workflows planifiés finissent par être désactivés.** Après une longue
période sans activité humaine dans le dépôt, GitHub coupe les crons et envoie
un avertissement par courriel. Un clic sur *Enable workflow* les relance.

**L'historique va gonfler.** Quatre commits par jour, indéfiniment. C'est sans
conséquence à cette échelle, mais ce n'est pas un dépôt qu'on garde propre.

**Pour tout arrêter :** onglet **Actions**, sélectionner un workflow dans la
colonne de gauche, menu `...` → *Disable workflow*. Le dépôt reste consultable.

---

## Le jour où il passera en privé

Par ordre d'importance :

**1. La facturation démarre.** Les minutes Actions sont décomptées d'un quota
mensuel — 2 000 sur un compte gratuit — et **chaque job est arrondi à la minute
supérieure, séparément**. Un job de quinze secondes coûte une minute pleine, et
une matrice de huit branches coûte huit minutes pour le même travail. Le seul
workflow qui tourne seul est le 01 : quatre fois par jour, soit environ
120 minutes par mois. Le commentaire au-dessus de son `cron:` rappelle comment
l'espacer. La limite de dépense d'un compte gratuit est à 0 € par défaut : le
quota épuisé, les workflows cessent de démarrer, aucune facture n'arrive.

**2. Passer en privé n'efface pas ce qui a été public.** Les forks déjà faits
subsistent, les clones aussi, et les archives tierces ne se rétractent pas.
Tout ce qui entre dans le dépôt pendant la phase publique doit être tenu pour
publié définitivement — y compris l'adresse de courriel des auteurs de commit,
que `git log` expose et qu'aucun changement de visibilité ne retire.

**3. Le code n'a rien à changer.** Les six workflows se comportent
identiquement dans les deux visibilités. Le filtrage du contexte du workflow 02
est déjà en liste blanche : il ne laisse sortir que des clés nommées une à une,
donc il reste correct qu'il y ait ou non des lecteurs anonymes.

Un point de vigilance pour la suite, tant que le dépôt est public : aucun
workflow ne se déclenche sur `pull_request`, et c'est ce qui empêche un fork
d'exécuter quoi que ce soit ici. Si ce déclencheur est ajouté un jour, relire
la question de près — `pull_request_target` en particulier donne à du code
venu d'un fork l'accès aux secrets du dépôt.

---

## Organisation des fichiers

```
.github/workflows/     les six workflows, un par mécanique
scripts/               la logique, sortie des blocs `run:`
entrees/               produit par les workflows — ne pas éditer à la main
fragments/             produit par le workflow 03
```

La logique vit dans `scripts/` plutôt que dans des blocs `run: |` pour deux
raisons : un heredoc à l'intérieur d'un YAML indenté conserve son indentation
et décale tout ce qu'il écrit, et un script se teste depuis son poste sans
consommer de run.

```bash
bash -n scripts/*.sh                    # vérifier la syntaxe
NUMERO=0 CTX_GITHUB='{"a":1}' CTX_RUNNER='{}' ./scripts/ecrire-contexte.sh
```
