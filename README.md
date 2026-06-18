This is my kubernetes homelab

i am migrating from docker to a fully modern kubernetes solution for my media stack and future containers

currently all my containers are within docker and virtualised with portainer and therefor accessed with the same ip address and sistinguised by ports

host: 10.0.0.196

portainer: 9000
sonarr: 12003
radarr: 12004
bitwarden: 8011
animeprowlarr: 12031
bazarr: 12006
cleanuparr: 12032
plex
pocket-id : 12055
prowlarr: 12030
QB1: 12008
QB2: 12012
QB3A: 12017
radarranime: 12016
SN: 8080
sonarranime: 12015
tatulli: 12011
unpackarr: 12033


nginx: 10.0.0.195
pve1: 10.0.0.10
pve2: 10.0.0.11
pve3: 10.0.0.12
pve4: 10.0.0.13

current nginx proxies:
pocket-id.{domain}
prowlarr.{domain}
pve.{domain}
vault.{domain}

CF:
all above are proxied througgh CF with domain of jvcdc.com.au
