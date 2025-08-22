# Pull Request

## Description
Brief description of the changes in this PR.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Changes Made
- [ ] Added support for new instance types
- [ ] Fixed maxPods calculation issue
- [ ] Updated documentation
- [ ] Improved error handling
- [ ] Enhanced logging
- [ ] Other: ___________

## Instance Types Affected
- [ ] T3 series
- [ ] M5 series  
- [ ] C5 series
- [ ] R5 series
- [ ] M6i series
- [ ] Other: ___________

## Testing
- [ ] Tested in development environment
- [ ] Tested with Security Groups for Pods enabled
- [ ] Tested with Security Groups for Pods disabled
- [ ] Validated YAML syntax
- [ ] Ran validation script
- [ ] Updated documentation

## Test Results
```
# Include test output, node descriptions, or log excerpts
kubectl describe node <node-name> | grep -E "(instance-type|pods)"
```

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] New and existing tests pass locally

## Related Issues
Fixes #(issue number)
Closes #(issue number)
