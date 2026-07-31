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

# Le contexte github contient une clé token. GitHub la masque dans les logs,
# mais rien ne la masquerait dans un fichier commité : elle est retirée ici,
# avant la moindre écriture sur le disque. La clé event part aussi, parce que
# sur un push volumineux sa charge utile fait des milliers de lignes.
#
# Le filtrage reste en mémoire : un fichier temporaire hors du dépôt aurait
# contenu le jeton en clair, le temps du run, sur le disque du runner.
github_filtre=$(printf '%s' "$CTX_GITHUB" | jq 'del(.token, .event)')
runner_filtre=$(printf '%s' "$CTX_RUNNER" | jq '.')

retirees=$(printf '%s' "$CTX_GITHUB" \
  | jq -r '[keys[] | select(. == "token" or . == "event")] | join(", ")')

{
cat <<EOF
# Contexte d'exécution

Écrit par le workflow 02, run #${numero}, le $(date -u '+%Y-%m-%d %H:%M UTC').

## Contexte \`github\`

Clés retirées avant écriture : ${retirees:-aucune}.

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
