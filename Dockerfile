FROM alpine

ARG arch
ENV ARCH=${arch:-amd64}
ENV HELM_VERSION="v2.14.1"				\
    KUBECTL_VERSION="v1.14.1"
ENV HELM_SRC="https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" \
    KUBECTL_SRC="https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"

COPY run.sh /run.sh

RUN sed -i 's/dl-cdn.alpinelinux.org/ftp.halifax.rwth-aachen.de/g' /etc/apk/repositories \
 && apk add --update ca-certificates curl bash		\
 && curl -sL "${HELM_SRC}"| tar -zxvf - -C /tmp		\
 && mv /tmp/linux-${ARCH}/helm /usr/local/bin		\
 && curl -sLo /usr/local/bin/kubectl "${KUBECTL_SRC}"	\
 && chmod +x /usr/local/bin/kubectl			\
 && chmod +x /run.sh					\
 && helm init --client-only				\
 && rm -rf /var/cache/apk/* /tmp/*


CMD ["/run.sh"]
