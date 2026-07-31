#!/usr/bin/env bash
#
# Écrit un fragment numéroté. Appelé une fois par branche de la matrice du
# workflow 03, chaque appel s'exécutant sur une machine différente.
#
# Usage : generer-fragment.sh <indice>

set -euo pipefail

indice="${1:?indice du fragment attendu}"
case "$indice" in
  ''|*[!0-9]*) echo "Indice non numérique : $indice" >&2; exit 1 ;;
esac

mkdir -p fragments

cat > "fragments/fragment-${indice}.md" <<EOF
# Fragment ${indice}

| | |
|---|---|
| indice dans la matrice | ${indice} |
| écrit le | $(date -u '+%Y-%m-%d %H:%M:%S UTC') |
| machine | $(hostname) |
| run | ${GITHUB_RUN_NUMBER:-hors Actions} |

Ce fichier a été écrit sur une machine qui n'existe plus. Les autres fragments
du même run ont été écrits sur d'autres machines, sans aucun disque partagé :
c'est l'artefact qui les a tous fait redescendre vers le job de rassemblement.
EOF

echo "fragments/fragment-${indice}.md écrit."
