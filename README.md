# NVIDIA Drivers for OKD SCOS (ostree-native container)

This repository builds an **ostree-native container image** for OKD 4.x SCOS that bakes in the NVIDIA open-kernel modules and userspace libraries. It layers packages into the SCOS base using `rpm-ostree` and commits them via `ostree container commit`, producing an image you can roll out to SCOS nodes.

> Target: **OKD 4.18** • **CentOS Stream 9** userspace • **NVIDIA open kernel modules (DKMS)**

## What this image does

- Enables CentOS Stream repos and adds EPEL/EPEL-Next
- Overrides the kernel packages to a specific CS9 kernel version inside the image
- Installs `dkms`, compiles and installs **NVIDIA open** kernel modules (`kmod-nvidia-open-dkms`)
- Installs NVIDIA userspace (CUDA driver libs, tools like `nvidia-smi`, `nvidia-settings`, etc.)
- Commits the filesystem as an **ostree native container** so it can be used as the node OS

### Packages Versions

- **Kernel version**  
  The build detects the **latest** `kernel.x86_64` from CentOS Stream 9 at build time and pins it via `rpm-ostree override replace`.  
  The NVIDIA DKMS modules are compiled specifically for that kernel ABI.

- **NVIDIA driver version**  
  The driver version is also the **latest** `kmod-nvidia-open-dkms` from CentOS Stream 9 at build time.


## Build

In order to build the image first set the correct OKD version in `Dockerfile`
so that it is the same as in your cluster. Then build it with the following command
```
docker build -t <your-container-registry>/okd-nvidia-image:<version> .
```
where `<your-container-registry>` is the name of the registry used in your OKD cluster.
Then push the image using the following command
```
docker push <your-container-registry>/okd-nvidia-image:<version>
```

If you are pushing to the OKD internal registry you might need to login first (run `oc login --web` if the cli is not yet authenticated)
```
docker login -u $(oc whoami) -p $(oc whoami --show-token)
```

## Deploy (OKD / SCOS)

This image is intended as an **OS image** for SCOS nodes (ostree-native). There are two common rollout patterns:

1. **Set `osImageURL`** for a Machine Config Pool (MCP) to this image.
2. Use your existing OS management flow (e.g., custom bootstrap or image streams) that points nodes at this ostree container.


### Example: MachineConfigPool (MCP) with MachineConfig

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: nvidiapool
  namespace:
spec:
  machineConfigSelector:
    matchExpressions:
      - {key: machineconfiguration.openshift.io/role, operator: In, values: [worker,nvidia]}
  nodeSelector:
    matchLabels:
      feature.node.kubernetes.io/pci-10de.present: "true"
```
> Ensure that the [NFD operator](https://docs.okd.io/latest/hardware_enablement/psap-node-feature-discovery-operator.html) is installed in order to set the `nvidia` label for each node with an available NVIDIA GPU.

Then use this image inside the MCP where `<version>` is the desired version.
```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: nvidia
  name: os-layer-custom-nvidia-drivers
  namespace:
spec:
  osImageURL: <your-container-registry>/okd-nvidia-image:<version>
```

## Verifying on a node

After the pool updates and nodes reboot into the new OS image:

```bash
nvidia-smi
```

## License

This repository’s content is provided under BSD-3.
NVIDIA drivers and CUDA components are subject to NVIDIA’s licenses; ensure compliance with their terms.
