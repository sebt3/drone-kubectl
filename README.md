# drone-kubectl
[![Build Status](http://drone.cloud.infra.local/api/badges/seb/drone-kubectl/status.svg)](http://drone.cloud.infra.local/seb/drone-kubectl)

## Plugin for drone.io
Usage :
```
kind: pipeline
name: default
steps:
- name: kubectl
  image: <your repo here>/drone-kubectl
  settings:
    server:
      from_secret: kubernetes_server
    cert:
      from_secret: kubernetes_cert
    token:
      from_secret: kubernetes_token
    kubectl: 
      - "get pods"
      - "get ns"
    helm: 
      - "list"

---
kind: secret
name: kubernetes_server
get:
  path: drone-kubernetes
  name: server
---
kind: secret
name: kubernetes_cert
get:
  path: drone-kubernetes
  name: cert
---
kind: secret
name: kubernetes_token
get:
  path: drone-kubernetes
  name: token
```

The setting server is optional.

Use this to patch the image in a deployment :
```
kind: pipeline
name: default
steps:
- name: kubectl
  image: <your repo here>/drone-kubectl
  settings:
    cert:
      from_secret: kubernetes_cert
    token:
      from_secret: kubernetes_token
    patch_deploy: my_deploy
    namespace: toolchain
    container: my_container
    registry: docker.io
    repo: sebt3/my_image
    tag: 1.2.3
---
kind: secret
name: kubernetes_cert
get:
  path: drone-kubernetes
  name: cert
---
kind: secret
name: kubernetes_token
get:
  path: drone-kubernetes
  name: token
```

- patch_deploy: the deployment to patch
- namespace: default "default"
- container: the container in the pods to patch, default to the deployment name
- registry: the registry the image will be pulled from (can be omitted)
- repo: The image name, default to ${DRONE_REPO_NAME}
- tag: the image tag to use, by default will use the 1st tag in the .tags file, use "latest" if not found
