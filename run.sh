#!/bin/bash
# Inspired by https://github.com/honestbee/drone-kubernetes/blob/master/update.sh
#  and https://github.com/komljen/drone-kubectl-helm/blob/master/run.sh

kubectl config set-credentials default --token=${PLUGIN_TOKEN}
if [[ ! -z ${PLUGIN_SERVER} ]]; then
  PLUGIN_SERVER=https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}
fi
if [[ ! -z ${PLUGIN_CERT} ]]; then
  echo ${PLUGIN_CERT} | base64 -d >ca.crt
  kubectl config set-cluster default --server=${PLUGIN_SERVER} --certificate-authority=ca.crt
else
  echo "WARNING: Using insecure connection to cluster"
  kubectl config set-cluster default --server=${PLUGIN_SERVER} --insecure-skip-tls-verify=true
fi

echo "====================================="
find /run/secrets
echo "====================================="

kubectl config set-context default --cluster=default --user=default
kubectl config use-context default

# Run kubectl command
if [[ ! -z ${PLUGIN_KUBECTL} ]]; then
  echo "${PLUGIN_KUBECTL}"|sed 's/,/\n/g'|while read CMD;do 
    echo "====================================="
    echo "running : kubectl ${CMD}"
    kubectl ${CMD}
  done
fi

# Run helm command
if [[ ! -z ${PLUGIN_HELM} ]]; then
  echo "${PLUGIN_HELM}"|sed 's/,/\n/g'|while read CMD;do 
    echo "====================================="
    echo "running : helm ${CMD}"
    helm ${CMD}
  done
fi
