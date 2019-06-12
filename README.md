# drone-kubectl
[![Build Status](http://drone.cloud.infra.local/api/badges/seb/drone-kubectl/status.svg)](http://drone.cloud.infra.local/seb/drone-kubectl)

## Plugin for drone.io
### Basic usage
```
kind: pipeline
name: default
steps:
- name: kubectl
  image: sebt3/drone-kubectl
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


### Patch kubernetes ressources
```
kind: pipeline
name: default
steps:
- name: deployment
  image: sebt3/drone-kubectl
  settings:
    cert:
      from_secret: kubernetes_cert
    token:
      from_secret: kubernetes_token
    patch_deploy: my_deploy
    namespace: default
    container: my_container
    registry: docker.io
    repo: sebt3/my_image
    tag: 1.2.3

- name: statefulset
  image: sebt3/drone-kubectl
  settings:
    cert:
      from_secret: kubernetes_cert
    token:
      from_secret: kubernetes_token
    patch_statefulset: my_stateful
    namespace: default
    container: my_container
    registry: docker.io
    repo: sebt3/my_image
    tag: 1.2.3

- name: daemonset
  image: sebt3/drone-kubectl
  settings:
    cert:
      from_secret: kubernetes_cert
    token:
      from_secret: kubernetes_token
    patch_daemonset: my_daemon
    namespace: my_ns
    container: my_container
    registry: docker.io
    repo: sebt3/my_image
    tag: 1.2.3
```

- patch_deploy: the deployment to patch
- namespace: default "default"
- container: the container in the pods to patch, default to the deployment name
- registry: the registry the image will be pulled from (can be omitted)
- repo: The image name, default to ${DRONE_REPO_NAME}
- tag: the image tag to use, by default will use the 1st tag in the .tags file, use "latest" if not found

### Upgrade an helm install
```
kind: pipeline
name: default
steps:
- name: helm upgrade
  image: sebt3/drone-kubectl
  settings:
    cert:
      from_secret: kubernetes_cert
    token:
      from_secret: kubernetes_token
    upgrade_helm: gogs
    source: incubator/gogs
    tag: 1.2.3
    tag_value: image.tag
    registry: docker.io
    repo: sebt3/my_image
    image_value: image.repo
```

- upgrade_helm: the name of the helm install **required**
- source: source for the helm chart **required**
- image_value: setting name for the image to be changed using the value of the following 2
- registry: the registry the image will be pulled from (can be omitted)
- repo: The image name, default to ${DRONE_REPO_NAME}
- tag_value: setting name for the tag to be changed using the value of the following
- tag: the image tag to use, by default will use the 1st tag in the .tags file, use "latest" if not found

Either image_value or tag_value have to be set
