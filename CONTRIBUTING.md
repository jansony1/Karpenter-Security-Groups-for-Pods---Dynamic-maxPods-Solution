# Contributing to Karpenter Security Groups for Pods - Dynamic maxPods Solution

Thank you for your interest in contributing! We welcome contributions from the community.

## 🤝 How to Contribute

### Reporting Issues

1. **Search existing issues** first to avoid duplicates
2. **Use the issue template** when creating new issues
3. **Provide detailed information**:
   - EKS cluster version
   - Karpenter version
   - Instance types affected
   - Error messages and logs
   - Steps to reproduce

### Code Contributions

#### Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl configured to access an EKS cluster
- Basic understanding of Karpenter and Kubernetes
- Familiarity with AWS EC2 instance types and ENI limits

#### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes**
4. **Test thoroughly** using the validation script
5. **Commit and push**: `git commit -m "feat: description" && git push`
6. **Create a Pull Request**

#### Adding New Instance Types

When adding support for new instance types:

1. **Research ENI limits** for the instance type
2. **Update the calculation function** in `ec2nodeclass.yaml`:
   ```bash
   # Add new instance type
   "m7i.large")    default_max_pods=29;  reserved_enis=9 ;;
   ```
3. **Add to NodePool** instance type list in `nodepool.yaml`
4. **Update documentation** with the new instance type
5. **Test thoroughly** with actual workloads

#### Testing Requirements

- Deploy and verify in real EKS cluster
- Use the provided validation script: `./validation-script.sh`
- Test with both Security Groups for Pods enabled and disabled
- Update documentation and examples

## 📋 Pull Request Process

1. **Ensure your PR**:
   - Has a clear title and description
   - References related issues
   - Includes tests for new features
   - Updates documentation as needed

2. **PR Requirements**:
   - All validation scripts pass
   - No merge conflicts
   - Documentation updated
   - YAML files are valid

## 🏷️ Commit Message Guidelines

Use conventional commit format:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `test:` Test additions or modifications

Examples:
```
feat: add support for M7i instance series
fix: correct maxPods calculation for t3.micro
docs: update README with new instance types
```

## 🐛 Issue Template

When reporting bugs, please include:

```markdown
**Environment**
- EKS Version: 
- Karpenter Version: 
- Instance Type: 
- Security Groups for Pods: Enabled/Disabled

**Steps to Reproduce**
1. Deploy configuration...
2. Apply workload...
3. Observe error...

**Expected vs Actual Behavior**
What you expected vs what happened.

**Logs**
Include relevant logs from:
- `/var/log/karpenter-maxpods.log`
- `/var/log/sg-pods-check.log`
```

## 🔒 Security

If you discover a security vulnerability, please email the maintainers directly rather than creating a public issue.

## 🙏 Recognition

Contributors will be recognized in the README and release notes.

Thank you for helping make this project better! 🚀
