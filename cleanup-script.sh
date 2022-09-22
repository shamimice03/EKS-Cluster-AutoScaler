#!/bin/sh

#AWS-CLI, kubectl, and eksctl must be installed first on the system before executing the system.

read -p 'Enter the Cluster Name : ' clustername

export CLUSTER_NAME=$clustername
export POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`AmazonEKSClusterAutoscalerPolicy`].Arn' --output text)

# Delete cluster-autoscaler
kubectl delete -f cluster-autoscaler.yaml

# Delete IAM Role and Service Account　
eksctl delete iamserviceaccount  \
 --cluster=${CLUSTER_NAME}  \
 --name=cluster-autoscaler \
 --namespace=kube-system

# Delete policy
aws iam delete-policy --policy-arn ${POLICY_ARN}
