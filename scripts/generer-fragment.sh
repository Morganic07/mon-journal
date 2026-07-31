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

Comparer ce tableau avec celui des autres fragments du même run. Le nom d'hôte
est commun à toutes les machines de GitHub et ne prouve rien ; l'identifiant
machine et le runner alloué, eux, diffèrent d'un fragment à l'autre — cinq
machines distinctes, sans aucun disque partagé. C'est l'artefact qui les a
toutes fait redescendre vers le job de rassemblement.

L'uptime de quelques secondes dit le reste : la machine venait de naître, et
elle a été détruite juste après avoir écrit ce fichier.
EOF

echo "fragments/fragment-${indice}.md écrit."
