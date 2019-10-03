#!/bin/bash

# script to collect intalled node deps into a single folder for easier tarballing

for d in \
    /home/theia-dev/.yarn-global \
    /usr/local/share/.cache/yarn \
    /opt/app-root/src/.npm-global; do \
    if [[ -d ${d} ]]; then 
        mkdir -p /tmp/root-local/${d}; 
        rsync -aPrz ${d} /tmp/root-local/${d};
    fi; 
done