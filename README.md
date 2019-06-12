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
