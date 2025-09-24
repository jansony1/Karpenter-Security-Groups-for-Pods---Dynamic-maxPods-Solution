# 变更日志 - v2

## v2.0.0 (2025-08-21)

### 🌟 主要新特性

#### 1. 智能maxPods计算算法
- **新增**: 基于实例类型的ENI和IP限制动态计算maxPods
- **算法**: `adjusted_max_pods = default_max_pods - reserved_enis`
- **安全下限**: 确保最小值为10个pods
- **覆盖**: 支持T3、M5、C5、R5、M6i系列共30+种实例类型

#### 2. Security Groups for Pods自动检测
- **新增**: 自动检测集群是否启用Security Groups for Pods
- **检测方法**:
  - aws-node DaemonSet的ENABLE_POD_ENI环境变量
  - amazon-vpc-cni ConfigMap的enable-pod-eni配置
- **后台验证**: 节点加入集群后异步验证配置
- **日志记录**: 详细的检测过程和结果日志

#### 3. 多实例类型支持
- **扩展**: 从v1的2种实例类型扩展到30+种
- **系列支持**: T3、M5、C5、R5、M6i全系列
- **规格范围**: 从t3.micro到24xlarge的完整覆盖
- **智能选择**: Karpenter可根据工作负载自动选择最适合的实例类型

### 🔧 技术改进

#### 1. 增强的用户数据脚本
- **函数化**: 将maxPods计算逻辑封装为独立函数
- **模块化**: 分离实例类型检测、计算、验证逻辑
- **错误处理**: 更完善的异常情况处理
- **日志系统**: 多层次的日志记录机制
- **Unicode兼容**: 全英文注释，避免编码问题

#### 2. 后台检查机制
- **异步验证**: 创建独立的后台检查脚本
- **延迟执行**: 等待节点完全加入集群后进行检查
- **多重验证**: 通过多种方法验证Security Groups for Pods配置
- **持续监控**: 记录最终的kubelet配置参数

#### 3. 改进的NodePool配置
- **实例类型列表**: 明确列出所有支持的实例类型
- **版本标签**: 添加version=v2标签便于管理
- **兼容性**: 保持与v1版本的标签兼容性

### 📊 配置对比

#### maxPods计算对比
| 实例类型 | v1配置 | v2计算方法 | v2结果 | 改进 |
|----------|--------|------------|--------|------|
| m5.large | 20 | 29-9 | 20 | 一致 |
| m5.xlarge | 40 | 58-18 | 40 | 一致 |
| t3.large | 不支持 | 35-12 | 23 | 新增 |
| c5.4xlarge | 不支持 | 234-54 | 180 | 新增 |
| r5.16xlarge | 不支持 | 737-108 | 629 | 新增 |

#### 功能对比
| 功能 | v1 | v2 | 改进说明 |
|------|----|----|----------|
| 实例类型支持 | 2种 | 30+种 | 15倍扩展 |
| 计算方法 | 硬编码 | 智能算法 | 基于ENI限制 |
| SG for Pods | 不支持 | 自动检测 | 新增功能 |
| 日志记录 | 基础 | 详细 | 多层次日志 |
| 后台验证 | 无 | 有 | 新增机制 |

### 📁 文件结构

```
v2/
├── README.md                    # 使用文档
├── ec2nodeclass.yaml           # EC2NodeClass配置
├── nodepool.yaml               # NodePool配置
├── test-pod.yaml               # 单个测试Pod
├── test-multi-instances.yaml   # 多实例类型测试
├── trigger-*.yaml              # 特定实例类型触发Pod
├── deploy.sh                   # 部署脚本
├── cleanup.sh                  # 清理脚本
├── validation-script.sh        # 验证脚本
├── CHANGELOG.md                # 本文档
└── VERSION                     # 版本信息
```

### 🧪 测试验证

#### 验证的实例类型
- **c5.large**: maxPods=20 ✅ 验证通过
- **m5.xlarge**: maxPods=40 ✅ 验证通过
- **t3.2xlarge**: maxPods=40 ✅ 验证通过

#### 验证的功能
- ✅ 智能maxPods计算算法
- ✅ Security Groups for Pods自动检测
- ✅ 多实例类型支持
- ✅ Pod调度和运行
- ✅ 日志记录完整性
- ✅ Unicode兼容性

### 🚀 生产就绪性

- ✅ **功能完整性**: 100%实现设计目标
- ✅ **稳定性**: 解决所有已知问题
- ✅ **可观测性**: 完整的日志记录机制
- ✅ **兼容性**: 支持IMDSv2和多种实例类型
- ✅ **扩展性**: 易于添加新实例类型支持

### 🔄 迁移指南

#### 从v1升级到v2
```bash
# 1. 清理v1配置
cd /Users/zhenyin/sg-with-karpenter/v1/
./cleanup.sh

# 2. 部署v2配置
cd /Users/zhenyin/sg-with-karpenter/v2/
./deploy.sh

# 3. 验证v2配置
./validation-script.sh
```

### 📈 性能预期

1. **更精确的资源利用**: 基于实际ENI限制计算maxPods
2. **更好的实例选择**: 支持更多实例类型，Karpenter可做出更优选择
3. **更智能的配置**: 自动适应Security Groups for Pods配置

---

**发布日期**: 2025-08-21
**基于版本**: v1.0.0
**兼容性**: Kubernetes 1.30+, Karpenter v1.x
