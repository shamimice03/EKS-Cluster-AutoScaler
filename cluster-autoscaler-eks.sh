#!/bin/sh

#AWS-CLI, kubectl, and eksctl must be installed first on the system before executing the system.

read -p 'Enter the Cluster Name : ' clustername

export CLUSTER_NAME=$clustername

echo -e "\nCluster Name : ${CLUSTER_NAME}"
echo -e "\nIf you want to proceed with above informaton, type \"yes\" or \"no\": " 
read value

if [ $value == "yes" ]
then
   
    #Create an OIDC provider for the cluster
    export OIDC_ID=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
    echo ${OIDC_ID}
    export CHECK=$(aws iam list-open-id-connect-providers | grep ${OIDC_ID})
    
    if [ -z "$CHECK" ]
    then
          eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve
    else
          echo "\$OIDC Provider already exists"
    fi
    
    
    #Create an IAM-POLICY and extract POLICY_ARN
    curl https://raw.githubusercontent.com/shamimice03/EKS-Cluster-AutoScaler/main/AmazonEKSClusterAutoscalerPolicy.json > AmazonEKSClusterAutoscalerPolicy.json

    # Create an IAM Policy
    aws iam create-policy  \
    --policy-name AmazonEKSClusterAutoscalerPolicy \
    --policy-document file://AmazonEKSClusterAutoscalerPolicy.json

    # Save the POLICY_ARN as an environment variable
    export POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`AmazonEKSClusterAutoscalerPolicy`].Arn' --output text)
    echo ${POLICY_ARN}
    
    # Create a Service Account and IAM Role with POLICY 
    export ROLE_NAME='AmazonEKSClusterAutoscalerRole'
    export SA_NAME='cluster-autoscaler'
    
    eksctl create iamserviceaccount \
    --name=${SA_NAME} \    
    --role-name ${ROLE_NAME} \
    --attach-policy-arn=${POLICY_ARN} \
    --cluster=${CLUSTER_NAME} \
    --namespace=kube-system \
    --override-existing-serviceaccounts \
    --approve
    
    export ROLE_ARN=$(aws iam list-roles --query 'Roles[?RoleName==`AmazonEKSClusterAutoscalerRole`].Arn' --output text)
    
    # Deploy Cluster-Autoscaler

    # Download the manifest file
    curl https://raw.githubusercontent.com/shamimice03/EKS-Cluster-AutoScaler/main/cluster-autoscaler.yaml > cluster-autoscaler.yaml

    # Replace <ROLE ARN> place holder with "ROLE_ARN" environment variable 
    sed  -i  "s#<ROLE ARN>#$ROLE_ARN#" cluster-autoscaler.yaml

    # Replace the <YOUR CLUSTER NAME> placeholder with the CLUSTER_NAME and 
    # Two commands under the the cluster-autoscaler deployment
    printf -v spc %12s      #adding spaces
    sed -i "s#<YOUR CLUSTER NAME>#$CLUSTER_NAME\n${spc}- --balance-similar-node-groups\n${spc}- --skip-nodes-with-system-pods=false#g" cluster-autoscaler.yaml

    # Deploy the manifest file
    kubectl create -f cluster-autoscaler.yaml
 
else
    echo -e "See you next time, Good Luck.\n" 
    exit
fi
