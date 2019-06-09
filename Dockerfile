FROM alpine

ARGS arch arm64
ENV HELM_VERSION="v2.14.1"				\
    KUBECTL_VERSION="v1.14.1"				\
    HELM_SRC="https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-${arch}.tar.gz" \
    KUBECTL_SRC="https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${arch}/kubectl"

COPY run.sh /run.sh

RUN apk add --update ca-certificates			\
 && apk add -t deps curl				\
 && apk add bash					\
 && curl -Lo /tmp/helm.tar.gz "${HELM_SRC}"		\
 && tar -xvf /tmp/helm.tar.gz -C /tmp			\
 && mv /tmp/linux-${arch}/helm /usr/local/bin		\
 && curl -Lo /usr/local/bin/kubectl "${KUBECTL_SRC}"	\
 && chmod +x /usr/local/bin/kubectl			\
 && apk del --purge deps				\
 && chmod +x /run.sh					\
 && rm /var/cache/apk/* /tmp/*


CMD ["/run.sh"]
