#!/bin/bash
# Inspired by https://github.com/honestbee/drone-kubernetes/blob/master/update.sh
#  and https://github.com/komljen/drone-kubectl-helm/blob/master/run.sh

#if [[ ! -z ${KUBERNETES_TOKEN} ]]; then
#  KUBERNETES_TOKEN=$KUBERNETES_TOKEN
#fi

#if [[ ! -z ${KUBERNETES_SERVER} ]]; then
#  KUBERNETES_SERVER=$KUBERNETES_SERVER
#fi

#if [[ ! -z ${KUBERNETES_CERT} ]]; then
#  KUBERNETES_CERT=${KUBERNETES_CERT}
#fi

echo "------------------------------"
env|grep -i PLUGIN
echo "------------------------------"
env
echo "------------------------------"

kubectl config set-credentials default --token=${PLUGIN_TOKEN}
if [[ ! -z ${KUBERNETES_CERT} ]]; then
  echo ${PLUGIN_CERT} | base64 -d >ca.crt
  kubectl config set-cluster default --server=${PLUGIN_SERVER} --certificate-authority=ca.crt
else
  echo "WARNING: Using insecure connection to cluster"
  kubectl config set-cluster default --server=${PLUGIN_SERVER} --insecure-skip-tls-verify=true
fi

kubectl config set-context default --cluster=default --user=default
kubectl config use-context default

# Run kubectl command
if [[ ! -z ${PLUGIN_KUBECTL} ]]; then
  IFS=',' read -r -a CMDS <<< "${PLUGIN_KUBECTL}"
  for CMD in ${CMDS[@]}; do
    echo "running : kubectl ${CMD}"
    kubectl ${CMD}
  done
fi

# Run helm command
if [[ ! -z ${PLUGIN_HELM} ]]; then
  IFS=',' read -r -a CMDS <<< "${PLUGIN_HELM}"
  for CMD in ${CMDS[@]}; do
    helm ${CMD}
  done
fi
