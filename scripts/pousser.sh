#!/usr/bin/env bash
#
# Commit l'arbre de travail et le pousse, en réessayant après rebase si la
# branche distante a bougé entre-temps — le cas quand plusieurs jobs poussent
# en parallèle.
#
# Usage : pousser.sh "<message de commit>" [nombre de tentatives]

set -euo pipefail

message="${1:?message de commit attendu en premier argument}"
tentatives="${2:-5}"

branche="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branche" = "HEAD" ]; then
  echo "HEAD est détaché : impossible de savoir sur quelle branche pousser." >&2
  echo "Ajouter 'ref: \${{ github.ref_name }}' aux paramètres de checkout." >&2
  exit 1
fi

# Identité du robot intégré à Actions. Cette adresse noreply est celle que
# GitHub associe au compte github-actions[bot] : sans elle, les commits ne
# sont pas rattachés au bot dans l'interface.
git config user.name  "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git add -A

# Un workflow planifié tourne même quand rien n'a changé. Sans cette sortie
# anticipée, `git commit` échoue et fait passer le run en rouge sans raison.
if git diff --cached --quiet; then
  echo "Rien à commiter : l'arbre est identique au dernier commit."
  exit 0
fi

git commit -m "$message"

for essai in $(seq 1 "$tentatives"); do
  # On pousse explicitement vers origin/<branche> plutôt que de compter sur
  # un upstream configuré : selon la façon dont le dépôt a été cloné, la
  # branche locale peut ne suivre aucune branche distante.
  if git push origin "HEAD:$branche"; then
    echo "Poussé à la tentative $essai."
    exit 0
  fi

  echo "Push refusé (tentative $essai/$tentatives) : la branche distante a bougé."

  if [ "$essai" -eq "$tentatives" ]; then
    break
  fi

  if ! git pull --rebase origin "$branche"; then
    git rebase --abort || true
    echo "Rebase impossible : les deux côtés ont modifié les mêmes lignes." >&2
    echo "Faire écrire chaque job dans un fichier distinct, ou sérialiser les" >&2
    echo "jobs avec un bloc concurrency." >&2
    exit 1
  fi

  sleep $(( essai * 2 ))
done

echo "Abandon après $tentatives tentatives de push." >&2
exit 1
