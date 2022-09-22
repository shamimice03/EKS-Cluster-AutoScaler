#!/bin/sh

export ROLE_ARN=$(aws iam list-roles --query 'Roles[?RoleName==`AmazonEKSClusterAutoscalerRole`].Arn' --output text)
export CLUSTER_NAME=kubehub-cluster-01

# Download the manifest file
curl https://raw.githubusercontent.com/shamimice03/EKS-Cluster-AutoScaler/main/cluster-autoscaler.yaml > cluster-autoscaler.yaml

# Replace <ROLE ARN> place holder with "ROLE_ARN" environment variable 
sed -i "s#<ROLE ARN>#$ROLE_ARN#" cluster-autoscaler.yaml

# Replace the <YOUR CLUSTER NAME> placeholder with the CLUSTER_NAME and 
# Two commands under the the cluster-autoscaler deployment
printf -v spc %12s
sed -i "s#<YOUR CLUSTER NAME>#$CLUSTER_NAME\n${spc}- --balance-similar-node-groups\n${spc}- --skip-nodes-with-system-pods=false#g" cluster-autoscaler.yaml

# Deploy the manifest file
kubectl create -f cluster-autoscaler.yaml
