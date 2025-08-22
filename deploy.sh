#!/bin/bash

set -e

echo "🚀 开始部署 Karpenter 动态 maxPods 配置 v2..."

# 检查集群名称配置
CLUSTER_NAME_IN_CONFIG=$(grep -o 'nlb-test-cluster' ec2nodeclass.yaml || echo "")
if [ "$CLUSTER_NAME_IN_CONFIG" = "nlb-test-cluster" ]; then
    echo "⚠️  警告: 检测到默认集群名称 'nlb-test-cluster'"
    echo "请更新 ec2nodeclass.yaml 中的集群名称为您的实际集群名称"
    echo ""
    echo "当前集群上下文:"
    kubectl config current-context
    echo ""
    read -p "是否继续部署? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "部署已取消"
        exit 1
    fi
fi

# 检查kubectl连接
if ! kubectl cluster-info --request-timeout=10s > /dev/null 2>&1; then
    echo "❌ 无法连接到Kubernetes集群"
    echo "请检查kubectl配置和集群连接"
    exit 1
fi

echo "✅ kubectl 和集群连接正常"

echo "🌟 v2版本新特性:"
echo "  • 🧮 智能maxPods计算算法"
echo "  • 🔒 Security Groups for Pods自动检测"
echo "  • 📊 支持T3/M5/C5/R5/M6i系列实例"
echo "  • 📝 详细的计算和检测日志"
echo "  • 🔄 后台配置验证机制"
echo ""

echo "📦 部署 EC2NodeClass v2..."
kubectl apply -f ec2nodeclass.yaml
echo "✅ EC2NodeClass v2 部署成功"

echo "📦 部署 NodePool v2..."
kubectl apply -f nodepool.yaml
echo "✅ NodePool v2 部署成功"

echo "🔍 验证部署状态..."
echo "检查 EC2NodeClass:"
kubectl get ec2nodeclass m5-dynamic-nodeclass-v2

echo ""
echo "检查 NodePool:"
kubectl get nodepool m5-dynamic-nodepool-v2

echo ""
echo "📋 支持的实例类型:"
echo "  T3系列: t3.micro → t3.2xlarge (2-40 pods)"
echo "  M5系列: m5.large → m5.24xlarge (20-629 pods)"
echo "  C5系列: c5.large → c5.24xlarge (20-629 pods)"
echo "  R5系列: r5.large → r5.24xlarge (20-629 pods)"
echo "  M6i系列: m6i.large → m6i.24xlarge (20-629 pods)"

echo "⏳ 等待资源就绪..."
sleep 5

echo "🎉 v2版本部署完成！"

echo "📋 部署信息:"
echo "  - EC2NodeClass: m5-dynamic-nodeclass-v2"
echo "  - NodePool: m5-dynamic-nodepool-v2"
echo "  - 节点标签: node-type=m5-dynamic-v2"
echo "  - 计算算法: 默认maxPods - 预留ENI (最小10)"
echo "  - SG for Pods: 自动检测和优化"
echo ""

echo "📝 测试命令:"
echo "1. 测试小实例类型 (t3/小型m5):"
echo "   kubectl apply -f test-multi-instances.yaml"
echo ""
echo "2. 测试中等实例类型 (m5.xlarge等):"
echo "   kubectl apply -f test-pod.yaml"
echo ""
echo "3. 测试特定实例类型:"
echo "   kubectl apply -f trigger-c5-large-small.yaml  # c5.large"
echo "   kubectl apply -f trigger-m5-xlarge.yaml       # m5.xlarge"
echo ""
echo "4. 监控节点创建:"
echo "   kubectl get nodeclaims -w"
echo "   kubectl get nodes -o wide"
echo ""

echo "🔍 验证命令:"
echo "1. 检查节点maxPods配置:"
echo "   kubectl describe node <node-name> | grep -E '(instance-type|pods)'"
echo ""
echo "2. 检查实例计算日志:"
echo "   aws ssm send-command --instance-ids <id> --document-name 'AWS-RunShellScript' \\"
echo "     --parameters 'commands=[\"cat /var/log/karpenter-maxpods.log\"]' --region us-west-2"
echo ""
echo "3. 运行完整验证:"
echo "   ./validation-script.sh"
echo ""

echo "✨ v2版本部署脚本执行完成！"
echo "💡 提示: v2版本会根据实例类型智能计算maxPods，并自动检测Security Groups for Pods配置"
