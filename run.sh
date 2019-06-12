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

RC=0
DONE=0

### Defining variable for patches
if [[ ! -z ${PLUGIN_PATCH_DEPLOY} ]] || [[ ! -z ${PLUGIN_UPGRADE_HELM} ]]; then
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


### Run helm upgrade
if [[ ! -z ${PLUGIN_UPGRADE_HELM} ]] &&  [[ ! -z ${PLUGIN_SOURCE} ]]; then
	CMD=""
	if [[ ! -z ${PLUGIN_TAG_VALUE} ]];then
		CMD=" --set ${PLUGIN_TAG_VALUE}=$tag"
	fi
	if [[ ! -z ${PLUGIN_IMAGE_VALUE} ]];then
		CMD=" --set ${PLUGIN_IMAGE_VALUE}=$image"
	fi
	if [[ ! -z ${CMD} ]];then
		echo "====================================="
		echo "#helm upgrade --reuse-values $CMD ${PLUGIN_UPGRADE_HELM} ${PLUGIN_SOURCE}"
		if ! helm upgrade --reuse-values $CMD ${PLUGIN_UPGRADE_HELM} ${PLUGIN_SOURCE};then
			echo "helm upgrade FAILED!"
			RC=$(($RC+1))
		fi
	else
		echo "ERROR: both 'upgrade_helm' and 'source' settings are required"
		RC=$(($RC+1))
	fi
elif [[ ! -z ${PLUGIN_UPGRADE_HELM} ]] ||  [[ ! -z ${PLUGIN_SOURCE} ]];then
	echo "ERROR: both 'upgrade_helm' and 'source' settings are required"
	RC=$(($RC+1))
fi

### Run helm command
if [[ ! -z ${PLUGIN_HELM} ]]; then
	echo "${PLUGIN_HELM}"|sed 's/,/\n/g'|while read CMD;do 
		echo "====================================="
		echo "# helm ${CMD}"
		if ! helm ${CMD};then
			echo "helm FAILED!"
			RC=$(($RC+1))
		fi
	done
fi

### Patching deployment
if [[ ! -z ${PLUGIN_PATCH_DEPLOY} ]]; then
	DONE=1
	echo "${PLUGIN_PATCH_DEPLOY}"|sed 's/,/\n/g'|while read deploy;do 
		name="${PLUGIN_CONTAINER:-"${deploy}"}"
		echo ${PLUGIN_NAMESPACE:-"default"}|while read ns;do 
			echo "====================================="
			echo "Patching deployment $deploy in namespace $ns to use $image as image for $name container"
			
			if ! kubectl patch deploy -n "$ns" "${deploy}" --patch '{"spec": {"template": {"spec": {"containers": [{"image": "'"$image"'","name": "'"$name"'"}]}}}}';then
				echo "Patching FAILED !"
				RC=$(($RC+1))
			fi
		done
	done
fi
### Patching statefulset
if [[ ! -z ${PLUGIN_PATCH_STATEFULSET} ]]; then
	DONE=1
	echo "${PLUGIN_PATCH_STATEFULSET}"|sed 's/,/\n/g'|while read deploy;do 
		name="${PLUGIN_CONTAINER:-"${deploy}"}"
		echo ${PLUGIN_NAMESPACE:-"default"}|while read ns;do 
			echo "====================================="
			echo "Patching statefulset $deploy in namespace $ns to use $image as image for $name container"
			
			if ! kubectl patch statefulset -n "$ns" "${deploy}" --patch '{"spec": {"template": {"spec": {"containers": [{"image": "'"$image"'","name": "'"$name"'"}]}}}}';then
				echo "Patching FAILED !"
				RC=$(($RC+1))
			fi
		done
	done
fi
### Patching daemonset
if [[ ! -z ${PLUGIN_PATCH_DAEMONSET} ]]; then
	DONE=1
	echo "${PLUGIN_PATCH_DAEMONSET}"|sed 's/,/\n/g'|while read deploy;do 
		name="${PLUGIN_CONTAINER:-"${deploy}"}"
		echo ${PLUGIN_NAMESPACE:-"default"}|while read ns;do 
			echo "====================================="
			echo "Patching daemonset $deploy in namespace $ns to use $image as image for $name container"
			
			if ! kubectl patch daemonset -n "$ns" "${deploy}" --patch '{"spec": {"template": {"spec": {"containers": [{"image": "'"$image"'","name": "'"$name"'"}]}}}}';then
				echo "Patching FAILED !"
				RC=$(($RC+1))
			fi
		done
	done
fi

### Run kubectl command
if [[ ! -z ${PLUGIN_KUBECTL} ]]; then
	DONE=1
	echo "${PLUGIN_KUBECTL}"|sed 's/,/\n/g'|while read CMD;do 
		echo "====================================="
		echo "# kubectl ${CMD}"
		if ! kubectl ${CMD};then
			echo "kubectl FAILED!"
			RC=$(($RC+1))
		fi
	done
fi

if [ $DONE -eq 0 ];then
	echo "The plugin did nothing"
	exit 1
fi
exit $RC
