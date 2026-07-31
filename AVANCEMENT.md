# Avancement

## Epic 1 — Socle

- [x] **1.1** Dépôt git local sur `main`, `.gitignore` en place.
      *Critère : `git status` propre après le premier commit.*
- [x] **1.2** `scripts/pousser.sh` commite, pousse, et réessaie après rebase.
      *Critère : `bash -n` passe ; sortie 0 sans erreur quand rien n'a changé.*
- [x] **1.3** Dépôt créé sur GitHub et poussé, public pour commencer.
      *Vérifié : visibilité `PUBLIC`, six workflows actifs dans l'onglet
      Actions. Adresse noreply utilisée pour les commits, config locale au
      dépôt.*

## Epic 2 — Les six mécaniques

- [x] **2.1** `01 · Battement` écrit une ligne et la pousse.
      *Vérifié : run #1 en `workflow_dispatch`, commit `a1f8c08` par
      `github-actions[bot]`, `entrees/battements.md` créé.*
- [x] **2.2** `02 · Contexte` écrit le contexte sans fuiter le jeton.
      *Vérifié : commit `2bc37c5`. La liste blanche a écarté 22 clés, dont
      `token` et `secret_source` — cette dernière serait passée avec l'ancien
      filtrage par liste noire.*
- [x] **2.3** `03 · Matrice` génère N fragments et les commite en un passage.
      *Vérifié après deux corrections : les 5 fichiers sont réécrits dans le
      commit `fragments : run 4`, par 5 runners distincts (`…192` à `…196`).
      Le premier run semblait correct mais ne l'était pas — voir les deux
      pièges consignés dans le README.*
- [x] **2.4** Le non-déclenchement est démontré.
      *Vérifié sans avoir eu besoin de lancer `04` : le push humain a
      déclenché `04b`, le commit `a1f8c08` poussé par le workflow 01 ne l'a
      pas fait. Deux push, un seul run de `04b`. Confirmé ensuite avec le
      workflow dédié : `04` a poussé le commit `92a30da`, et le compteur de
      runs de `04b` est resté à 13 avant comme après.*
- [x] **2.5** `05 · Collision` fait perdre au moins une voie.
      *Vérifié, et mieux que demandé : les trois issues sur un seul run. La
      voie b passe du premier coup, la voie a est refusée une fois, la voie c
      deux fois — refusée, rebasée, refusée à nouveau, puis poussée à la
      troisième tentative. Les trois lignes sont dans le dépôt.*

## Epic 3 — Vie du dépôt

- [x] **3.1** Le cron se déclenche seul.
      *Vérifié : runs #2 et #3, déclencheur `schedule`, commits `d482bde` et
      `bccc2e2`. Mesure au passage — réglé sur `*/5` pendant 3 h 20, il a
      produit 2 exécutions au lieu de 40, à des heures ne correspondant à
      aucun créneau. Consigné dans le README.*
- [x] **3.2** Bascule en privé.
      *Fait : visibilité `PRIVATE`, après une phase publique sans aucun fork,
      étoile ni observateur. Cron laissé à `17 */6 * * *` — 120 min/mois, 6 %
      du quota, choix assumé plutôt que l'espacement suggéré. Le README et le
      commentaire du cron sont passés au présent.*
      *Reste à faire une fois : relever la consommation réelle après une
      semaine sur github.com/settings/billing et la comparer aux 120 min
      annoncées.*

## Pistes, si l'envie vient

- Lever le garde-fou anti-domino avec une clé de déploiement, et poser un
  garde-fou anti-boucle explicite à la place.
- Un workflow `workflow_call` réutilisable, appelé par les autres.
- Un environnement avec règle de protection, pour voir un job attendre une
  validation manuelle.
- Un job `container:` pour comparer avec l'exécution directe sur le runner.
