#!/bin/bash

NC='\033[0m' # No Color
Red='\033[0;31m' # Red
Green='\033[0;32m' # Green
White='\033[0;37m' # White
Yellow='\033[0;33m' # Yellow

KUBE_VERSION=1.32

echo -e "${White}------- Check environment --------${NC}"

if ! command -v aws &> /dev/null
then
    echo -e "aws-cli: ${Red}KO${NC}. Report to the readme"
    exit
fi
echo -e "aws-cli: ${Green}OK${NC}"
if ! command -v eksctl &> /dev/null
then
    echo -e "eksctl: ${Red}KO${NC}. Report to the readme"
    exit
fi
echo -e "eksctl: ${Green}OK${NC}"
if ! command -v helm &> /dev/null
then
    echo -e "helm: ${Red}KO${NC}. Report to the readme"
    exit
fi
echo -e "helm: ${Green}OK${NC}"
if ! command -v kubectl &> /dev/null
then
    echo -e "kubectl: ${Red}KO${NC}. Report to the readme"
    exit
fi
echo -e "kubectl: ${Green}OK${NC}"

set -e

echo -e "\n${White}------- Login to AWS using SSO --------${NC}"
aws sso login

echo -e "\n${White}------- Creating Kube Cluster --------${NC}"
echo -e "This can take a while"

eksctl create cluster --name platform-engineering-demo --version $KUBE_VERSION
eksctl utils associate-iam-oidc-provider --region=eu-west-3 --cluster=platform-engineering-demo --approve
eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster platform-engineering-demo \
    --role-name AmazonEKS_EBS_CSI_DriverRole_PEDemo \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve
eksctl create addon --name aws-ebs-csi-driver --cluster platform-engineering-demo --service-account-role-arn arn:aws:iam::448878779811:role/AmazonEKS_EBS_CSI_DriverRole_PEDemo --force

echo -e "\n${White}------- ArgoCD Setup --------${NC}"

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
