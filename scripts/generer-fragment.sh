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

# L'identifiant machine n'est relevé que sur un runner. Sur un poste, il
# identifie durablement l'installation : un essai local suivi d'un commit le
# publierait dans un dépôt public. Sur une VM détruite après le run, il ne
# désigne plus rien.
if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  machine=$(cut -c1-12 /etc/machine-id 2>/dev/null || echo indisponible)
else
  machine="non relevé hors CI"
fi

# Quatre identifiants plutôt qu'un seul, parce que `hostname` ne distingue
# pas les runners de GitHub : les machines d'un même run le partagent. Ce qui
# varie réellement d'un job à l'autre, c'est RUNNER_NAME et machine-id ; et
# l'uptime dit à quel point la machine est fraîche.
cat > "fragments/fragment-${indice}.md" <<EOF
# Fragment ${indice}

| | |
|---|---|
| indice dans la matrice | ${indice} |
| écrit le | $(date -u '+%Y-%m-%d %H:%M:%S UTC') |
| runner alloué | ${RUNNER_NAME:-hors Actions} |
| nom d'hôte | $(hostname) |
| identifiant machine | ${machine} |
| allumée depuis | $(awk '{printf "%d s", $1}' /proc/uptime 2>/dev/null || echo '?') |
| run | ${GITHUB_RUN_NUMBER:-hors Actions} |

Comparer ce tableau avec celui des autres fragments du même run.

Deux champs ne prouvent rien, et c'est la leçon : le nom d'hôte est commun à
toute la flotte, et l'identifiant machine est identique partout parce qu'il est
gravé dans l'image disque dont chaque machine est clonée. Deux identifiants
qu'on croirait uniques, et qui ne le sont pas.

Ce qui distingue réellement : le runner alloué, dont le numéro change à chaque
job, et l'uptime — cinq durées différentes relevées à la même seconde ne
peuvent pas sortir d'une seule machine. Chacune venait de naître et a été
détruite juste après avoir écrit ce fichier, sans jamais partager de disque
avec les autres. C'est l'artefact qui les a toutes fait redescendre vers le
job de rassemblement.
EOF

echo "fragments/fragment-${indice}.md écrit."
