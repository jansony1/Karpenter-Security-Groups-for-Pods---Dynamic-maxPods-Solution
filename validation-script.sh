#!/bin/bash

# Karpenter 动态 maxPods 配置验证脚本 - v2
# 创建时间: 2025-08-21
# 版本: v2

set -e

echo "🔍 开始验证 Karpenter 动态 maxPods 配置 v2..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 检查AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI 未找到，请先安装 AWS CLI${NC}"
    exit 1
fi

# 检查kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl 未找到，请先安装 kubectl${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 工具检查通过${NC}"

# 1. 检查v2配置是否部署
echo -e "\n${BLUE}📋 检查v2配置部署状态...${NC}"

EC2NODECLASS_STATUS=$(kubectl get ec2nodeclass m5-dynamic-nodeclass-v2 --no-headers 2>/dev/null | wc -l)
NODEPOOL_STATUS=$(kubectl get nodepool m5-dynamic-nodepool-v2 --no-headers 2>/dev/null | wc -l)

if [ "$EC2NODECLASS_STATUS" -eq 0 ]; then
    echo -e "${RED}❌ EC2NodeClass v2 未部署${NC}"
    echo "请先运行: ./deploy.sh"
    exit 1
fi

if [ "$NODEPOOL_STATUS" -eq 0 ]; then
    echo -e "${RED}❌ NodePool v2 未部署${NC}"
    echo "请先运行: ./deploy.sh"
    exit 1
fi

echo -e "${GREEN}✅ v2配置已部署${NC}"

# 2. 检查v2相关节点
echo -e "\n${BLUE}🔍 检查v2相关节点...${NC}"

V2_NODES=$(kubectl get nodes -l node-type=m5-dynamic-v2 --no-headers 2>/dev/null)
NODE_COUNT=$(echo "$V2_NODES" | grep -v '^$' | wc -l)

if [ "$NODE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  未发现v2节点，可能需要部署测试Pod触发节点创建${NC}"
    echo "建议运行: kubectl apply -f test/test-pod.yaml"
else
    echo -e "${GREEN}✅ 发现 $NODE_COUNT 个v2节点${NC}"
    echo "$V2_NODES"
fi

# 3. 验证节点maxPods配置
if [ "$NODE_COUNT" -gt 0 ]; then
    echo -e "\n${BLUE}🔍 验证节点maxPods配置...${NC}"
    
    while IFS= read -r line; do
        if [ ! -z "$line" ]; then
            NODE_NAME=$(echo "$line" | awk '{print $1}')
            echo -e "\n${PURPLE}节点: $NODE_NAME${NC}"
            
            # 获取实例类型和maxPods
            INSTANCE_TYPE=$(kubectl get node "$NODE_NAME" -o jsonpath='{.metadata.labels.node\.kubernetes\.io/instance-type}')
            MAX_PODS_CAPACITY=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.capacity.pods}')
            MAX_PODS_ALLOCATABLE=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.allocatable.pods}')
            
            echo "  实例类型: $INSTANCE_TYPE"
            echo "  Capacity pods: $MAX_PODS_CAPACITY"
            echo "  Allocatable pods: $MAX_PODS_ALLOCATABLE"
            
            # 根据实例类型验证maxPods是否正确
            case $INSTANCE_TYPE in
                "t3.micro")    EXPECTED_PODS=2 ;;
                "t3.small")    EXPECTED_PODS=7 ;;
                "t3.medium")   EXPECTED_PODS=11 ;;
                "t3.large")    EXPECTED_PODS=23 ;;
                "t3.xlarge"|"t3.2xlarge") EXPECTED_PODS=40 ;;
                "m5.large"|"c5.large"|"r5.large"|"m6i.large") EXPECTED_PODS=20 ;;
                "m5.xlarge"|"c5.xlarge"|"r5.xlarge"|"m6i.xlarge") EXPECTED_PODS=40 ;;
                "m5.2xlarge"|"c5.2xlarge"|"r5.2xlarge"|"m6i.2xlarge") EXPECTED_PODS=40 ;;
                "m5.4xlarge"|"c5.4xlarge"|"r5.4xlarge"|"m6i.4xlarge") EXPECTED_PODS=180 ;;
                "m5.8xlarge"|"c5.9xlarge"|"r5.8xlarge"|"m6i.8xlarge") EXPECTED_PODS=180 ;;
                "m5.12xlarge"|"c5.12xlarge"|"r5.12xlarge"|"m6i.12xlarge") EXPECTED_PODS=180 ;;
                "m5.16xlarge"|"c5.18xlarge"|"r5.16xlarge"|"m6i.16xlarge") EXPECTED_PODS=629 ;;
                "m5.24xlarge"|"c5.24xlarge"|"r5.24xlarge"|"m6i.24xlarge") EXPECTED_PODS=629 ;;
                *) EXPECTED_PODS="未知" ;;
            esac
            
            if [ "$EXPECTED_PODS" != "未知" ]; then
                if [ "$MAX_PODS_CAPACITY" -eq "$EXPECTED_PODS" ]; then
                    echo -e "  ${GREEN}✅ maxPods配置正确 (期望: $EXPECTED_PODS, 实际: $MAX_PODS_CAPACITY)${NC}"
                else
                    echo -e "  ${RED}❌ maxPods配置错误 (期望: $EXPECTED_PODS, 实际: $MAX_PODS_CAPACITY)${NC}"
                fi
            else
                echo -e "  ${YELLOW}⚠️  未知实例类型，无法验证maxPods${NC}"
            fi
        fi
    done <<< "$V2_NODES"
fi

# 4. 检查实例日志（如果有节点）
if [ "$NODE_COUNT" -gt 0 ]; then
    echo -e "\n${BLUE}📝 检查实例日志...${NC}"
    
    # 获取第一个节点的实例ID
    FIRST_NODE=$(echo "$V2_NODES" | head -1 | awk '{print $1}')
    INSTANCE_ID=$(kubectl get node "$FIRST_NODE" -o jsonpath='{.spec.providerID}' | cut -d'/' -f5)
    
    if [ ! -z "$INSTANCE_ID" ]; then
        echo "检查实例 $INSTANCE_ID 的日志..."
        
        # 检查主要配置日志
        echo -e "\n${PURPLE}主要配置日志:${NC}"
        COMMAND_ID=$(aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["cat /var/log/karpenter-maxpods.log 2>/dev/null || echo \"日志文件不存在\""]' \
            --region us-west-2 \
            --query 'Command.CommandId' \
            --output text 2>/dev/null)
        
        if [ ! -z "$COMMAND_ID" ]; then
            sleep 5
            aws ssm get-command-invocation \
                --command-id "$COMMAND_ID" \
                --instance-id "$INSTANCE_ID" \
                --region us-west-2 \
                --query 'StandardOutputContent' \
                --output text 2>/dev/null || echo "无法获取日志"
        fi
        
        # 检查Security Groups for Pods检查日志
        echo -e "\n${PURPLE}Security Groups for Pods检查日志:${NC}"
        COMMAND_ID2=$(aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["cat /var/log/sg-pods-check.log 2>/dev/null || echo \"检查日志文件不存在\""]' \
            --region us-west-2 \
            --query 'Command.CommandId' \
            --output text 2>/dev/null)
        
        if [ ! -z "$COMMAND_ID2" ]; then
            sleep 5
            aws ssm get-command-invocation \
                --command-id "$COMMAND_ID2" \
                --instance-id "$INSTANCE_ID" \
                --region us-west-2 \
                --query 'StandardOutputContent' \
                --output text 2>/dev/null || echo "无法获取检查日志"
        fi
        
        # 检查kubelet参数
        echo -e "\n${PURPLE}kubelet参数验证:${NC}"
        COMMAND_ID3=$(aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["ps aux | grep kubelet | grep max-pods | head -1"]' \
            --region us-west-2 \
            --query 'Command.CommandId' \
            --output text 2>/dev/null)
        
        if [ ! -z "$COMMAND_ID3" ]; then
            sleep 5
            aws ssm get-command-invocation \
                --command-id "$COMMAND_ID3" \
                --instance-id "$INSTANCE_ID" \
                --region us-west-2 \
                --query 'StandardOutputContent' \
                --output text 2>/dev/null || echo "无法获取kubelet参数"
        fi
    fi
fi

# 5. 检查Security Groups for Pods集群配置
echo -e "\n${BLUE}🔒 检查集群Security Groups for Pods配置...${NC}"

# 检查aws-node DaemonSet
SG_PODS_DAEMONSET=$(kubectl get daemonset aws-node -n kube-system -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="ENABLE_POD_ENI")].value}' 2>/dev/null || echo "未找到")
echo "aws-node DaemonSet ENABLE_POD_ENI: $SG_PODS_DAEMONSET"

# 检查ConfigMap
SG_PODS_CONFIGMAP=$(kubectl get configmap amazon-vpc-cni -n kube-system -o jsonpath='{.data.enable-pod-eni}' 2>/dev/null || echo "未找到")
echo "amazon-vpc-cni ConfigMap enable-pod-eni: $SG_PODS_CONFIGMAP"

if [ "$SG_PODS_DAEMONSET" = "true" ] || [ "$SG_PODS_CONFIGMAP" = "true" ]; then
    echo -e "${GREEN}✅ Security Groups for Pods 已启用${NC}"
else
    echo -e "${YELLOW}⚠️  Security Groups for Pods 未启用或检测失败${NC}"
fi

# 6. 总结
echo -e "\n${GREEN}🎉 v2版本验证完成！${NC}"
echo -e "${BLUE}📋 验证总结:${NC}"
echo "  - v2配置部署状态: ✅"
echo "  - v2节点数量: $NODE_COUNT"
if [ "$NODE_COUNT" -gt 0 ]; then
    echo "  - maxPods配置验证: 请查看上述详细结果"
    echo "  - 实例日志检查: 请查看上述日志输出"
fi
echo "  - Security Groups for Pods检测: 请查看上述配置状态"

echo -e "\n${YELLOW}💡 建议操作:${NC}"
if [ "$NODE_COUNT" -eq 0 ]; then
    echo "1. 部署测试Pod触发节点创建:"
    echo "   kubectl apply -f test/test-pod.yaml"
    echo "2. 等待节点创建完成后重新运行验证:"
    echo "   ./validation-script.sh"
else
    echo "1. 如果发现配置问题，可以重新部署:"
    echo "   ./cleanup.sh && ./deploy.sh"
    echo "2. 测试不同实例类型:"
    echo "   kubectl apply -f test-multi-instances.yaml"
fi

echo -e "\n${GREEN}✨ v2版本验证脚本执行完成！${NC}"
