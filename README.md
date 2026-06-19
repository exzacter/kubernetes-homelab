# This is my kubernetes homelab

i am migrating from docker to a fully modern kubernetes solution for my media stack and future containers

currently all my containers are within docker and virtualised with portainer and therefor accessed with the same ip address and sistinguised by ports

host: 10.0.0.196

- portainer: 9000
- sonarr: 12003
- radarr: 12004
- bitwarden: 8011
- animeprowlarr: 12031
- bazarr: 12006
- cleanuparr: 12032
- plex
- pocket-id : 12055
- prowlarr: 12030
- QB1: 12008
- QB2: 12012
- QB3A: 12017
- radarranime: 12016
- SN: 8080
- sonarranime: 12015
- tatulli: 12011
- unpackarr: 12033


- nginx: 10.0.0.195
- pve1: 10.0.0.10
- pve2: 10.0.0.11
- pve3: 10.0.0.12
- pve4: 10.0.0.13

### current nginx proxies:
- pocket-id.{domain}
- prowlarr.{domain}
- pve.{domain}
- vault.{domain}

### CF:
all above are proxied througgh CF with domain of jvcdc.com.au


## Why self-managed kubeadm
 
Chose `kubeadm` over k3s/Talos to own etcd, CNI, and upgrade mechanics directly rather than have them abstracted away — the explicit goal is understanding what managed Kubernetes (e.g. EKS) hides, not the fastest path to a working cluster.
 
## Infrastructure
 
| Host | CPU | Total RAM | Boot Mode | Role |
|---|---|---|---|---|
| pve | 16x Xeon E5530 @ 2.4GHz | 70.74 GiB | EFI | cp1 + worker2 (+ TrueNAS, co-located) |
| pve2 | 24x Xeon E5-2640 @ 2.5GHz | 70.59 GiB | EFI | cp2 + worker3 |
| pve3 | 12x Xeon E5-2430 v2 @ 2.5GHz | 62.74 GiB | Legacy BIOS | cp3 + worker4 |
| pve4 | 8x Xeon E5-2609 @ 2.4GHz | 78.56 GiB | EFI | worker1 only (no control-plane VM) |
 
8 VMs total: 3 control-plane, 4 worker, 1 admin (not a cluster member — holds `kubectl`/`helm`/`kubeseal`/`argocd`/`git` and cluster admin credentials; all cluster work happens here over SSH).
 
**Known constraints accepted, not solved:**
- TrueNAS and cp1 share a physical disk on `pve` (single-SSD host) — accepted for a homelab; would not accept in a production design.
- `pve3` is CPU-constrained relative to its control-plane + worker load — most likely host to show etcd latency issues under sustained worker load.
- `pve4` has the smallest local-disk pool (~50GB total) — kept to disk-light workloads only.
- CPU type set to `host` on all VMs for performance, given no live-migration requirement (no shared storage backing VM disks, so live migration isn't realistic here anyway).
## Stack
 
| Concern | Choice | Why |
|---|---|---|
| Cluster bootstrap | kubeadm | Manual control of etcd/CNI/upgrades |
| CNI | Cilium | eBPF model, closer to AWS VPC CNI than Calico |
| Persistent storage | NFS CSI driver → existing TrueNAS | Pod-level PVCs, not VM-disk-level NFS — keeps VM root disks on fast local storage, etcd off NFS entirely |
| GitOps | Argo CD + GitHub | Nothing applied to the cluster except through git; Argo CD itself bootstrapped once manually as the sole exception |
| Secrets | Sealed Secrets | Commit secrets to git safely |
| Ingress/TLS | ingress-nginx + MetalLB + cert-manager (Cloudflare DNS-01) | Replaces old NPM reverse-proxy setup |
| Backup | Velero + Backblaze B2 + separate etcd snapshots | App-level and cluster-state backup kept distinct |
| Observability | kube-prometheus-stack + Loki + Alloy | Metrics + logs, Alertmanager as the alerting backbone |
| Migration strategy | Parallel run | Old Docker stack stays up until each service is proven on k8s; nothing decommissioned early |
 
## Applications
 
- **Vaultwarden** — highest-priority service (holds all credentials). SQLite-backed, single replica only (no concurrent-writer support) — backup rigor here matters more than anywhere else in the stack.
- **Pocket ID** — SSO/auth provider.
- **Media stack** — Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent, SABnzbd, Unpackerr, Cleanuperr, Plex, Tautulli (linuxserver.io images). Needs a shared media/downloads volume (hardlink-compatible — single underlying NFS mount, not per-app dynamic provisioning) plus separate per-app config volumes.
- **Gitea** — stays on the existing Docker host. Explicitly not migrating.
No official Kubernetes packaging exists for most of the *arr stack (or most self-hosted software generally) — hand-rolled Deployment/PVC/Service manifests per app, rather than a generic community Helm chart or a compose-to-k8s converter, specifically so the exercise of writing the primitives by hand isn't skipped.
 
## Future goals / not yet built
 
**Cluster-level autoscaling (design stage, unbuilt):**
- Reserve headroom per host (e.g. don't allocate 100% of a host's spare capacity to its worker VM) specifically to leave room for vertical scaling later.
- On sustained memory pressure (Prometheus alert rule with a `for:` duration, not a custom cron/timer — avoids building parallel infrastructure to something Alertmanager already does), attempt vertical scale (memory hot-add) up to a pre-set ceiling per VM.
- **Blocking unknown:** whether memory hot-add actually works cleanly on this Proxmox version + guest OS combination. Needs to be manually verified before any automation is built around it — if it doesn't work, the design simplifies to horizontal-only.
- If at ceiling, scale horizontally — provision a new worker VM on whichever host has the largest remaining reserved-headroom pool (computed, not random; "random" only applies as a tiebreaker on an exact tie).
- Scale-down/leak question unresolved: a transient spike that triggers a hot-add currently has no defined path back down, which would slowly consume reserved headroom across hosts over time if left as scale-up-only.
- Decided to keep this firmly separate from pod-level autoscaling — Kubernetes' own VPA/HPA (using the kube-prometheus-stack metrics already being deployed) covers "a pod needs more resources" natively, no custom tooling required. The custom automation above is scoped only to "the cluster itself needs more total capacity," which has no mature off-the-shelf answer on bare-metal/Proxmox the way it does on managed cloud providers.
- If automated further, the GitOps-correct shape is: Alertmanager → webhook → opens a PR against the Terraform config with a proposed change → human approves/merges → CI applies. Not: alert fires → infrastructure changes directly. Keeps the "nothing applied except through git" principle intact even for infrastructure-layer changes, not just cluster-layer ones.
## Naming convention
 
`pve{n}-prod-k8s-{cp|worker}{n}` for cluster VMs (e.g. `pve1-prod-k8s-cp1`), admin VM named separately as it isn't a cluster member.
