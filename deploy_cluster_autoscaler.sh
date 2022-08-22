# download files

git clone https://github.com/shamimice03/EKS-Cluster-AutoScaler.git  /eks-clusterAutoScaler
cd /eks-clusterAutoScaler

#!/bin/bash

# deploy cluster
eksctl create cluster -f managed-nodegroup.yaml

# OIDC ID
CLUSTER_NAME=kubehub-cluster-01
eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve

# create IAM Policy
aws iam create-policy  \
--policy-name AmazonEKSClusterAutoscalerPolicy \
--policy-document file:///eks-clusterAutoScaler/AmazonEKSClusterAutoscalerPolicy.json

# save the POLICY_ARN as an environment variable
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`AmazonEKSClusterAutoscalerPolicy`].Arn' --output text)


# create IAM Role with POLICY 
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --name=cluster-autoscaler \
  --attach-policy-arn=$POLICY_ARN \
  --role-name AmazonEKSClusterAutoscalerRole \
  --namespace=kube-system \
  --override-existing-serviceaccounts \
  --approve

# save the ROLE_ARN as an environment variable
ROLE_ARN=$(aws iam list-roles --query 'Roles[?RoleName==`AmazonEKSClusterAutoscalerRole`].Arn' --output text)

# manipulate cluster-autoscaler manifest file

sed  -i "s/<ROLE ARN>/$ROLE_ARN/" cluster-autoscaler.yaml
sed  "s/<YOUR CLUSTER NAME>/$CLUSTER_NAME\n            - --balance-similar-node-groups\n            - --skip-nodes-with-system-pods=false/g" cluster-autoscaler.yaml


# deploy cluster-autoscaler
kubectl create -f cluster-autoscaler.yaml



















