#!/bin/bash
# Inspired by https://github.com/honestbee/drone-kubernetes/blob/master/update.sh
#  and https://github.com/komljen/drone-kubectl-helm/blob/master/run.sh

### Init phase
kubectl config set-credentials default --token=${PLUGIN_TOKEN}
if [[ -z ${PLUGIN_SERVER} ]]; then
	PLUGIN_SERVER="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}"
fi
if [[ ! -z ${PLUGIN_CERT} ]]; then
	echo ${PLUGIN_CERT} | base64 -d >ca.crt
	kubectl config set-cluster default --server=${PLUGIN_SERVER} --certificate-authority=ca.crt
else
	echo "WARNING: Using insecure connection to cluster"
	kubectl config set-cluster default --server=${PLUGIN_SERVER} --insecure-skip-tls-verify=true
fi

kubectl config set-context default --cluster=default --user=default
kubectl config use-context default

### Patching deployment
if [[ ! -z ${PLUGIN_PATCH_DEPLOY} ]]; then
	if [[ ! -z ${PLUGIN_TAG} ]]; then
		tag=${PLUGIN_TAG}
	elif [ -f ".tags" ];then
		tag=$(sed 's/,.*//' .tags)
	else
		echo "Warning: no tags set and no .tags file available, using 'latest'"
		tag="latest"
	fi
	image="${PLUGIN_REGISTRY}/${PLUGIN_REPO:-"${DRONE_REPO_NAME}"}:$tag"
	image="${image#/}"
fi
if [[ ! -z ${PLUGIN_PATCH_DEPLOY} ]]; then
	echo "${PLUGIN_PATCH_DEPLOY}"|sed 's/,/\n/g'|while read deploy;do 
		name="${PLUGIN_CONTAINER:-"${deploy}"}"
		echo ${PLUGIN_NAMESPACE:-"default"}|while read ns;do 
			echo "====================================="
			echo "Patching deployement $deploy in namespace $ns to use $image as image for $name container"
			kubectl patch deploy -n "$ns" "${deploy}" --patch '{"spec": {"template": {"spec": {"containers": [{"image": "'"$image"'","name": "'"$name"'"}]}}}}'
		done
	done
fi

# Run kubectl command
if [[ ! -z ${PLUGIN_KUBECTL} ]]; then
	echo "${PLUGIN_KUBECTL}"|sed 's/,/\n/g'|while read CMD;do 
		echo "====================================="
		echo "# kubectl ${CMD}"
		kubectl ${CMD}
	done
fi

# Run helm command
if [[ ! -z ${PLUGIN_HELM} ]]; then
	echo "${PLUGIN_HELM}"|sed 's/,/\n/g'|while read CMD;do 
		echo "====================================="
		echo "# helm ${CMD}"
		helm ${CMD}
	done
fi
