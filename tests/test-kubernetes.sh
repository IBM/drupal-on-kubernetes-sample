# Copyright [2018] IBM Corp. All Rights Reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

#!/bin/bash

# This script is intended to be run by Travis CI. If running elsewhere, invoke
# it with: TRAVIS_PULL_REQUEST=false [path to script]

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

kubeclt_clean() {
    echo "Cleaning cluster"
    kubectl delete pvc,deployment,service,replicaset -l app=drupal
    sleep 30s
    kubectl delete pv local-volume-1 local-volume-2 local-volume-3
}

kubectl_config() {
    echo "Configuring kubectl"
    #shellcheck disable=SC2091
    $(bx cs cluster-config "$CLUSTER_NAME" | grep export)
}


kubectl_deploy() {
    kubeclt_clean

    echo "Running scripts/quickstart.sh"
    "$(dirname "$0")"/../scripts/quickstart.sh

    echo "Waiting for pods to be running"
    i=0
    while [[ $(kubectl get pods -l app=drupal | grep -c Running) -ne 2 ]]; do
        if [[ ! "$i" -lt 24 ]]; then
            echo "Timeout waiting on pods to be ready"
            test_failed "$0"
        fi
        sleep 10
        echo "...$i * 10 seconds elapsed..."
        ((i++))
    done
    echo "All pods are running"

    echo "Waiting for service to be available"
    sleep 120
}

verify_deploy(){
    echo "Verifying deployment was successful"
    IPS=$(bx cs workers "$CLUSTER_NAME" | awk '{ print $2 }' | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
    for IP in $IPS; do
        if ! curl -sS "$IP":30080; then
            test_failed "$0"
        fi
        echo
    done
}

main(){
    is_pull_request "$0"

    if ! kubectl_config; then
        test_failed "$0"
    elif ! kubectl_deploy; then
        test_failed "$0"
    elif ! verify_deploy; then
        test_failed "$0"
    else
        test_passed "$0"
    fi
}

main "$@"
