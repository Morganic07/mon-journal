# Avancement

## Epic 1 — Socle

- [x] **1.1** Dépôt git local sur `main`, `.gitignore` en place.
      *Critère : `git status` propre après le premier commit.*
- [x] **1.2** `scripts/pousser.sh` commite, pousse, et réessaie après rebase.
      *Critère : `bash -n` passe ; sortie 0 sans erreur quand rien n'a changé.*
- [ ] **1.3** Dépôt privé créé sur GitHub et poussé.
      *Critère : `gh repo view --json visibility` renvoie `PRIVATE`.*

## Epic 2 — Les six mécaniques

- [ ] **2.1** `01 · Battement` écrit une ligne et la pousse.
      *Critère : après un `workflow_dispatch`, `entrees/battements.md` contient
      une ligne de plus, commitée par `github-actions[bot]`.*
- [ ] **2.2** `02 · Contexte` écrit le contexte sans fuiter le jeton.
      *Critère : `grep -c 'ghs_' entrees/contexte.md` renvoie 0, et le fichier
      annonce `Clés retirées : token, event`.*
- [ ] **2.3** `03 · Matrice` génère N fragments et les commite en un passage.
      *Critère : lancé avec `combien = 5`, produit `fragments/fragment-1.md` à
      `fragment-5.md` en un seul commit.*
- [ ] **2.4** `04 · Domino` démontre le non-déclenchement.
      *Critère : après un run de `04`, aucun run de `04b` dans l'onglet
      Actions ; après un push manuel, `04b` se déclenche.*
- [ ] **2.5** `05 · Collision` fait perdre au moins une voie.
      *Critère : le journal d'au moins une voie contient « Push refusé », suivi
      d'un rebase et d'une seconde tentative réussie.*

## Epic 3 — Vie du dépôt

- [ ] **3.1** Le cron se déclenche seul.
      *Critère : un run de `01` avec `schedule` comme déclencheur apparaît dans
      l'historique sans intervention.*
- [ ] **3.2** Consommation de minutes relevée après une semaine.
      *Critère : chiffre noté ici, comparé aux ~120 min/mois annoncés.*

## Pistes, si l'envie vient

- Lever le garde-fou anti-domino avec une clé de déploiement, et poser un
  garde-fou anti-boucle explicite à la place.
- Un workflow `workflow_call` réutilisable, appelé par les autres.
- Un environnement avec règle de protection, pour voir un job attendre une
  validation manuelle.
- Un job `container:` pour comparer avec l'exécution directe sur le runner.
