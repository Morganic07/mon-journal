# Contexte d'exécution

Écrit par le workflow 02, run #1, le 2026-07-31 18:40 UTC.

## Contexte `github`

Seules les clés d'une liste blanche sont écrites ici. Clés écartées :
action_ref, action_repository, actor_id, artifact_cache_size_limit, artifacts, artifacts_list, base_ref, env, event, event_path, head_ref, output, path, ref_protected, repositoryUrl, repository_id, repository_owner_id, secret_source, state, step_summary, token, workflow_sha.

```json
{
  "job": "inspecter",
  "ref": "refs/heads/main",
  "sha": "332e0ab7c7ac561689ececf8b50e43eb3d84bbf5",
  "repository": "Morganic07/mon-journal",
  "repository_owner": "Morganic07",
  "run_id": "30656050192",
  "run_number": "1",
  "retention_days": "90",
  "run_attempt": "1",
  "repository_visibility": "public",
  "actor": "Morganic07",
  "workflow": "02 · Contexte",
  "event_name": "workflow_dispatch",
  "server_url": "https://github.com",
  "api_url": "https://api.github.com",
  "graphql_url": "https://api.github.com/graphql",
  "ref_name": "main",
  "ref_type": "branch",
  "workflow_ref": "Morganic07/mon-journal/.github/workflows/02-contexte.yml@refs/heads/main",
  "triggering_actor": "Morganic07",
  "workspace": "/home/runner/work/mon-journal/mon-journal",
  "action": "__run"
}
```

## Contexte `runner`

```json
{
  "os": "Linux",
  "arch": "X64",
  "name": "GitHub Actions 1000000166",
  "environment": "github-hosted",
  "tool_cache": "/opt/hostedtoolcache",
  "temp": "/home/runner/work/_temp",
  "workspace": "/home/runner/work/mon-journal"
}
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
GITHUB_WORKSPACE  = /home/runner/work/mon-journal/mon-journal
GITHUB_EVENT_PATH = /home/runner/work/_temp/_github_workflow/event.json
RUNNER_OS         = Linux
processeurs       = 4
mémoire           = 15Gi
disque disponible = 88G
```
