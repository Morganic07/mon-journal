# Fragment 4

| | |
|---|---|
| indice dans la matrice | 4 |
| écrit le | 2026-07-31 18:52:17 UTC |
| runner alloué | GitHub Actions 1000000194 |
| nom d'hôte | runnervmvrwv9 |
| identifiant machine | 0e4bba8396ef |
| allumée depuis | 41 s |
| run | 4 |

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
