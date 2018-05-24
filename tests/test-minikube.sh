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

#!/bin/bash -ex

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

setup_minikube() {
	export CHANGE_MINIKUBE_NONE_USER=true
	curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
	curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.25.2/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
	sudo -E minikube start --vm-driver=none --kubernetes-version=v1.9.0
	minikube update-context
	JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done
}

kubectl_deploy() {
	echo "Running scripts/quickstart.sh"
	"$(dirname "$0")"/../scripts/quickstart.sh
}

verify_deploy(){
	echo "Verifying deployment was successful"
	if ! sleep 1 && curl -sS "$(kubectl get svc drupal | grep drupal | awk '{ print $2 }')":30080; then
		test_failed "$0"
	fi
}

main(){
	if ! setup_minikube; then
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
