#!/usr/bin/env bash
#
# Écrit entrees/contexte.md à partir des contextes sérialisés que le workflow
# passe par l'environnement.
#
# Attendu dans l'environnement : CTX_GITHUB, CTX_RUNNER. NUMERO est facultatif.
#
# La logique vit dans un script plutôt que dans un bloc `run: |` parce qu'un
# heredoc à l'intérieur d'un YAML indenté conserve son indentation : `<<-EOF`
# ne mange que les tabulations, pas les espaces, et le markdown produit
# ressortirait décalé de dix colonnes.

set -euo pipefail

: "${CTX_GITHUB:?contexte github attendu}"
: "${CTX_RUNNER:?contexte runner attendu}"
numero="${NUMERO:-inconnu}"

mkdir -p entrees

# Le contexte github contient une clé token, et sa charge utile event pèse des
# milliers de lignes sur un push volumineux. Ni l'une ni l'autre n'a sa place
# dans un fichier commité.
#
# Le filtrage se fait par liste blanche, pas par `del(.token, .event)`. Une
# liste noire laisse passer tout ce qu'on n'a pas prévu : le jour où GitHub
# ajoute une clé au contexte, elle atterrirait dans le dépôt sans qu'on l'ait
# décidé. Ici, ce qui n'est pas nommé ne sort pas — le fichier reste sûr même
# si le dépôt devient public, et même si le contexte s'enrichit.
PUBLIABLES='[
  "event_name", "ref", "ref_name", "ref_type", "sha",
  "run_id", "run_number", "run_attempt", "retention_days",
  "workflow", "workflow_ref", "job", "action", "actor", "triggering_actor",
  "repository", "repository_owner", "repository_visibility",
  "server_url", "api_url", "graphql_url", "workspace"
]'

github_filtre=$(printf '%s' "$CTX_GITHUB" \
  | jq --argjson garder "$PUBLIABLES" \
       'with_entries(select(.key as $k | $garder | index($k)))')
runner_filtre=$(printf '%s' "$CTX_RUNNER" | jq '.')

# Ce qui a été écarté est annoncé dans le fichier : sans cette ligne, on ne
# saurait pas qu'un filtrage a eu lieu, ni qu'il faudrait le relire.
ecartees=$(printf '%s' "$CTX_GITHUB" \
  | jq -r --argjson garder "$PUBLIABLES" \
       '[keys[] | select(. as $k | $garder | index($k) | not)] | join(", ")')

{
cat <<EOF
# Contexte d'exécution

Écrit par le workflow 02, run #${numero}, le $(date -u '+%Y-%m-%d %H:%M UTC').

## Contexte \`github\`

Seules les clés d'une liste blanche sont écrites ici. Clés écartées :
${ecartees:-aucune}.

\`\`\`json
EOF

printf '%s\n' "$github_filtre"

cat <<'EOF'
```

## Contexte `runner`

```json
EOF

printf '%s\n' "$runner_filtre"

cat <<'EOF'
```

## Fichiers-canaux du runner

Ces variables ne contiennent pas une valeur mais un chemin de fichier : on y
écrit une ligne pour communiquer avec la suite du workflow.

| Variable | Ce que produit une écriture dedans |
|---|---|
| `GITHUB_ENV` | une variable d'environnement pour les étapes suivantes |
| `GITHUB_OUTPUT` | une sortie de l'étape, lisible par les autres jobs via `needs` |
| `GITHUB_STEP_SUMMARY` | du markdown affiché sur la page du run |
| `GITHUB_PATH` | une entrée ajoutée au PATH des étapes suivantes |

## Machine du run

```
EOF

printf 'GITHUB_WORKSPACE  = %s\n' "${GITHUB_WORKSPACE:-}"
printf 'GITHUB_EVENT_PATH = %s\n' "${GITHUB_EVENT_PATH:-}"
printf 'RUNNER_OS         = %s\n' "${RUNNER_OS:-}"
printf 'processeurs       = %s\n' "$(nproc)"
printf 'mémoire           = %s\n' "$(free -h | awk '/^Mem:/ {print $2}')"
printf 'disque disponible = %s\n' "$(df -h --output=avail / | tail -n 1 | tr -d ' ')"
echo '```'
} > entrees/contexte.md

echo "entrees/contexte.md écrit ($(wc -l < entrees/contexte.md) lignes)."
