##Cluster-Autoscaler Installation Process

#### Download this repository to a folder on your system 

```
git clone https://github.com/shamimice03/EKS-Cluster-AutoScaler.git  /eks-clusterAutoScaler
cd /eks-clusterAutoScaler
```

#### Deploy EKS cluster using eksctl 

```
eksctl create cluster -f managed-nodegroup.yaml
```

#### Check EKS cluster 

```
kubectl get svc
kubectl get nodes
```

#### Create OIDC ID
```
CLUSTER_NAME=kubehub-cluster-01
eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve
```

#### Create IAM Policy
```
aws iam create-policy  \
--policy-name AmazonEKSClusterAutoscalerPolicy \
--policy-document file:///eks-clusterAutoScaler/AmazonEKSClusterAutoscalerPolicy.json
```

#### Save the POLICY_ARN as an environment variable
```
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`AmazonEKSClusterAutoscalerPolicy`].Arn' --output text)
```

#### Create IAM Role with POLICY 
```
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --name=cluster-autoscaler \
  --attach-policy-arn=$POLICY_ARN \
  --role-name AmazonEKSClusterAutoscalerRole \
  --namespace=kube-system \
  --override-existing-serviceaccounts \
  --approve
```

#### Save the ROLE_ARN as an environment variable
```
ROLE_ARN=$(aws iam list-roles --query 'Roles[?RoleName==`AmazonEKSClusterAutoscalerRole`].Arn' --output text)
```

#### Manipulate cluster-autoscaler manifest file
```
sed  -i "s/<ROLE ARN>/$ROLE_ARN/" cluster-autoscaler.yaml
sed  "s/<YOUR CLUSTER NAME>/$CLUSTER_NAME\n            - --balance-similar-node-groups\n            - --skip-nodes-with-system-pods=false/g" cluster-autoscaler.yaml
```

#### Deploy cluster-autoscaler
```
kubectl create -f cluster-autoscaler.yaml
```
