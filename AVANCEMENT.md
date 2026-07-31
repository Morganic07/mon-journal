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
- [ ] **2.2** `02 · Contexte` écrit le contexte sans fuiter le jeton.
      *Critère : `grep -c 'ghs_' entrees/contexte.md` renvoie 0, et le fichier
      annonce `Clés retirées : token, event`.*
- [ ] **2.3** `03 · Matrice` génère N fragments et les commite en un passage.
      *Critère : lancé avec `combien = 5`, produit `fragments/fragment-1.md` à
      `fragment-5.md` en un seul commit.*
- [x] **2.4** Le non-déclenchement est démontré.
      *Vérifié sans avoir eu besoin de lancer `04` : le push humain a
      déclenché `04b`, le commit `a1f8c08` poussé par le workflow 01 ne l'a
      pas fait. Deux push, un seul run de `04b`. Lancer `04` reste utile pour
      voir la même chose avec un workflow dédié.*
- [ ] **2.5** `05 · Collision` fait perdre au moins une voie.
      *Critère : le journal d'au moins une voie contient « Push refusé », suivi
      d'un rebase et d'une seconde tentative réussie.*

## Epic 3 — Vie du dépôt

- [ ] **3.1** Le cron se déclenche seul.
      *Critère : un run de `01` avec `schedule` comme déclencheur apparaît dans
      l'historique sans intervention.*
- [ ] **3.2** Bascule en privé, le jour venu.
      *Critère : le cron espacé selon le commentaire du workflow 01, et la
      consommation relevée après une semaine, comparée aux ~120 min/mois
      annoncés. Sans objet tant que le dépôt est public.*

## Pistes, si l'envie vient

- Lever le garde-fou anti-domino avec une clé de déploiement, et poser un
  garde-fou anti-boucle explicite à la place.
- Un workflow `workflow_call` réutilisable, appelé par les autres.
- Un environnement avec règle de protection, pour voir un job attendre une
  validation manuelle.
- Un job `container:` pour comparer avec l'exécution directe sur le runner.
