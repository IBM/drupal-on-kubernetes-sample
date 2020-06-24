#!/bin/bash

kubectl create -f kubernetes/local-volumes.yaml
kubectl create -f kubernetes/postgres.yaml
kubectl create -f kubernetes/drupal.yaml
kubectl get nodes
kubectl get svc drupal
