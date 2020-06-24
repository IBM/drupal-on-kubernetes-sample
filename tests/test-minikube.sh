#!/bin/bash -ex

# shellcheck disable=SC1090
source "$(dirname "$0")"/../pattern-ci/scripts/resources.sh

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
	if ! kubectl_deploy; then
		test_failed "$0"
	elif ! verify_deploy; then
		test_failed "$0"
	else
		test_passed "$0"
	fi
}

main "$@"
