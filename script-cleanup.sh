#!/bin/sh

#AWS-CLI, kubectl, and eksctl must be installed first on the system before executing the system.

read -p 'Enter the Cluster Name : ' clustername

echo "Starting......"

export CLUSTER_NAME=$clustername
export POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`AmazonEKSClusterAutoscalerPolicy`].Arn' --output text)
export ROLE_NAME='AmazonEKSClusterAutoscalerRole'

echo "Deleting IAM Role and Policies"
# Delete IAM Role and Policies
aws iam detach-role-policy --role-name=${ROLE_NAME}  --policy-arn=${POLICY_ARN}
aws iam delete-role --role-name=${ROLE_NAME}
aws iam delete-policy --policy-arn=${POLICY_ARN}



# Delete IAM Role and Service Account　
eksctl delete iamserviceaccount  \
 --cluster=${CLUSTER_NAME}  \
 --name=cluster-autoscaler \
 --namespace=kube-system
 
# Delete cluster-autoscaler
kubectl delete -f cluster-autoscaler.yaml
