#!/bin/bash -ex
#
# Builds this container, including locally fetched plugins and replaces references to docker/quay/RHCC with specified container registry
# 
# see also https://github.com/eclipse/che/issues/14693
# 

if [[ $1 == "nightly" ]]; then
	registry="myquay.mycorp.com"
	nightly="nightly"
	now=`date +%Y%m%d-%H%M`
elif [[ $1 ]]; then
	registry="${1}"
	nightly="${1%%.*}" # first section of the URL replacement
	now="${nightly}-`date +%Y%m%d-%H%M`" # append timestamp
else
	echo "Must specify URL of internal registry to use, eg., $0 myquay.mycorp.com"
	echo "To fetch plugins but not do registry substitutions, use $0 nightly"
	echo "To push to quay, use $0 myquay.mycorp.com --push --squash"
	exit 1
fi

DOCKERFILE=build/dockerfiles/rhel.Dockerfile

# Extra step for air gap - replace references to docker.io, quay.io, registry.access.redhat.com, registry.redhat.io with internal registry
# inject this into the Dockerfile: RUN ./replace_container_repos.sh v3 myquay.mycorp.com
cat ${DOCKERFILE} | sed -e "s%#.*\(RUN ./check_plugins_location.sh v3\)%./replace_container_repos.sh v3 ${registry} && \1%" > ${DOCKERFILE}.2
mv ${DOCKERFILE}.2 ${DOCKERFILE}

now=`date +%Y%m%d-%H%M`
docker build . -f ${DOCKERFILE} -t quay.io/nickboldt/airgap-crw-plugin-registry:${nightly} --no-cache $3
docker tag quay.io/nickboldt/airgap-crw-plugin-registry:{${nightly},${now}}

if [[ $2 == "--push" ]]; then
	for d in ${nightly} ${now}; do
		docker push quay.io/nickboldt/airgap-crw-plugin-registry:${d} &
	done
	wait
else
	echo "To push these containers, do this:

"
	for d in ${nightly} ${now}; do
		echo "docker push quay.io/nickboldt/airgap-crw-plugin-registry:${d} &"
	done
fi

