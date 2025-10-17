# kubernetes-homelab
<h2>My kubernetes homelab</h2>

This is my journey to creating a kubernetes homelab.

Currently I have installed Talos Linux on one of my 3 Proxmox servers. This is for testing. Eventually for HA i want to expand across all 3 nodes with a control plane and worker nodes.

<h2>My Setup</h2>
All my cluster currently runs inside of my hypervisor of Proxmox. I might eventually make the switch to barebones talos if I become more confident.

- PVE1: DELL R720, 16 CORES, 70GB RAM, 100GB LOCAL STORAGE, 360GB LOCAL-LVM STORAGE
- PVE2: DELL R710, 24 CORES, 70GB RAM, 100GB LOCAL STORAGE, 2TB LOCAL-LVM STORAGE
- PVE3: DELL R610, 12 CORES, 25GB RAM, 75GB LOCAL STORAGE, 185GB LOCAL-LVM STORAGE

Control plane runs on PVE2 with the following specs:
- 4 CORES (1 SOCKET, 4 CORES, HOST), 4GB RAM, 112GB STORAGE

Woker nodes also run on PVE2 with the following specs:
- W1: 2 CORES (1 SOCKET, 2 CORES, HOST), 2GB RAM, 112GB STORAGE
- W2: 2 CORES (1 SOCKET, 2 CORES, HOST), 2GB RAM, 112GB STORAGE
- W3: 2 CORES (1 SOCKET, 2 CORES, HOST), 2GB RAM, 112GB STORAGE

<h2>To Do:</h2>

- [x] Install talos linx
- [x] setup fluxCD
- [x] setup a ingress controller
- [x] setup a loadbalancer 
- [ ] setup ssl certs for secure local websites using cloudflare (i think this uses a secret key so may need to setup azure keyvault first)
- [ ] cloudflared tunnels?
- [ ] vpns? 
- [ ] setup azure keyvault for secure keys
- [ ] setup nfs mounts
- [ ] test containers to ensure the above works

<h2>How i've installed</h2>


<h3>installing k8s (talos)</h3>
Currently I have followed <a href="https://www.talos.dev/v1.11/talos-guides/install/virtualized-platforms/proxmox/#installation">this</a>. There were only a few changes:
- When sending worker yaml to my 3 worker nodes I used a different export command and assigned each to the IP of the worker node e.g. ("export WORKER_IP1=10.0.2.51, export WORKER_IP3=10.0.2.52, export WORKER_IP3=10.0.2.53.") I then used the default command but changed $WORKER_IP to the value of the nodes.
- After i had bootstrapped and retrieved the kubeconfig I updated the command in "Using the Cluster" to use a different kubeconfig location and hard linked it using the full path.

# <h3>setting up fluxcd</h3>

- the only step really to integrate flux is bootstrapping it with your repo of choice.
- I chose github (obviously) and used the following as I wanted to use a deploy key

```bash
flux bootstrap git \
  --url=ssh://git@github.com/exzacter/kubernetes-homelab \
  --branch=main \
  --private-key-file=<path/to/ssh/private.key> \
  --path=clusters/kubernetes-homelab
```

- in full transparency I did encounter errors here as i never set the `kubeconfig` with the EXPORT command
- before the flux bootstrap use:

```bash
export KUBECONFIG=/path/to/your/kubeconfig
```

- a good tip so as to not need to do this every time is add it to your `bashrc` or `zshrc` (same with `export TALOSCONFIG=/path/to/talosconfig`)
- then bootstrap command, then fluxcd is officially setup.
- now this is the brain of your cluster and will deploy based on this repo

<h3>setting up traefik ingress and metallb loadbalancer</h3>

