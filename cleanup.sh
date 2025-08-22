#!/bin/bash

# Karpenter 动态 maxPods 配置清理脚本 - v2
# 创建时间: 2025-08-21
# 版本: v2

set -e

echo "🧹 开始清理 Karpenter 动态 maxPods 配置 v2..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 1. 删除测试Pod和Deployment
echo -e "${BLUE}🗑️  删除v2测试资源...${NC}"

# 删除单个测试Pod
if kubectl get pod test-dynamic-maxpods-v2 &> /dev/null; then
    kubectl delete pod test-dynamic-maxpods-v2
    echo -e "${GREEN}✅ 测试Pod v2已删除${NC}"
fi

# 删除多实例测试Deployment
if kubectl get deployment test-multi-instances-v2 &> /dev/null; then
    kubectl delete deployment test-multi-instances-v2
    echo -e "${GREEN}✅ 多实例测试Deployment已删除${NC}"
fi

# 删除大实例测试Pod
if kubectl get pod test-large-instance-v2 &> /dev/null; then
    kubectl delete pod test-large-instance-v2
    echo -e "${GREEN}✅ 大实例测试Pod已删除${NC}"
fi

# 2. 等待Pod完全删除
echo -e "${YELLOW}⏳ 等待Pod完全删除...${NC}"
sleep 15

# 3. 删除NodePool (这会触发节点删除)
echo -e "${BLUE}🗑️  删除NodePool v2...${NC}"
if kubectl get nodepool m5-dynamic-nodepool-v2 &> /dev/null; then
    kubectl delete nodepool m5-dynamic-nodepool-v2
    echo -e "${GREEN}✅ NodePool v2已删除${NC}"
else
    echo -e "${YELLOW}⚠️  NodePool v2不存在，跳过${NC}"
fi

# 4. 等待节点删除
echo -e "${YELLOW}⏳ 等待节点删除...${NC}"
sleep 30

# 5. 删除EC2NodeClass
echo -e "${BLUE}🗑️  删除EC2NodeClass v2...${NC}"
if kubectl get ec2nodeclass m5-dynamic-nodeclass-v2 &> /dev/null; then
    kubectl delete ec2nodeclass m5-dynamic-nodeclass-v2
    echo -e "${GREEN}✅ EC2NodeClass v2已删除${NC}"
else
    echo -e "${YELLOW}⚠️  EC2NodeClass v2不存在，跳过${NC}"
fi

# 6. 检查剩余资源
echo -e "${BLUE}🔍 检查剩余v2资源...${NC}"

echo "检查v2相关NodeClaims:"
NODECLAIMS=$(kubectl get nodeclaims -l karpenter.k8s.aws/ec2nodeclass=m5-dynamic-nodeclass-v2 --no-headers 2>/dev/null | wc -l)
if [ "$NODECLAIMS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  发现 $NODECLAIMS 个v2相关NodeClaim，正在删除...${NC}"
    kubectl delete nodeclaims -l karpenter.k8s.aws/ec2nodeclass=m5-dynamic-nodeclass-v2
fi

echo "检查v2相关节点:"
NODES=$(kubectl get nodes -l node-type=m5-dynamic-v2 --no-headers 2>/dev/null | wc -l)
if [ "$NODES" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  发现 $NODES 个v2相关节点，等待自动清理...${NC}"
    kubectl get nodes -l node-type=m5-dynamic-v2 -o wide
fi

# 7. 检查其他版本标签的节点
echo -e "\n${PURPLE}🔍 检查其他版本的节点:${NC}"
OTHER_NODES=$(kubectl get nodes -l version=v2 --no-headers 2>/dev/null | wc -l)
if [ "$OTHER_NODES" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  发现 $OTHER_NODES 个带有version=v2标签的节点${NC}"
    kubectl get nodes -l version=v2 -o wide
fi

# 8. 显示清理结果
echo -e "\n${GREEN}🎉 v2版本清理完成！${NC}"
echo -e "${BLUE}📋 清理总结:${NC}"
echo "  - ✅ v2测试Pod和Deployment已删除"
echo "  - ✅ NodePool v2已删除"
echo "  - ✅ EC2NodeClass v2已删除"
echo "  - ✅ 相关NodeClaim已删除"

if [ "$NODES" -gt 0 ] || [ "$OTHER_NODES" -gt 0 ]; then
    echo -e "\n${YELLOW}📝 注意事项:${NC}"
    echo "  - 节点可能需要几分钟时间完全删除"
    echo "  - 可以通过以下命令监控节点删除进度:"
    echo "    kubectl get nodes -l node-type=m5-dynamic-v2 -w"
    echo "    kubectl get nodes -l version=v2 -w"
fi

echo -e "\n${PURPLE}🔧 如果需要清理所有版本:${NC}"
echo "  # 清理v1版本"
echo "  cd ../v1 && ./cleanup.sh"
echo ""
echo "  # 清理所有karpenter相关节点"
echo "  kubectl get nodes -l managed-by=karpenter"

echo -e "\n${GREEN}✨ v2版本清理脚本执行完成！${NC}"
