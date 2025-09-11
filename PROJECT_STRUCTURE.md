# Project Structure

## Core Files (v3 - Latest)
- **ec2nodeclass-v3.yaml** - Main EC2NodeClass configuration with ENI reservation logic
- **nodepool-v3.yaml** - NodePool configuration supporting multiple instance types
- **test-instances-v3.yaml** - Test deployments for validation

## Documentation
- **README.md** - Main project documentation and quick start guide
- **VERIFICATION_RESULTS.md** - Detailed test results and validation data
- **SUPPORTED_INSTANCES.md** - Complete list of supported AWS instance types
- **QUICKSTART.md** - Rapid deployment guide
- **CONTRIBUTING.md** - Contribution guidelines
- **CHANGELOG.md** - Version history and changes

## Utilities
- **deploy.sh** - Automated deployment script
- **validation-script.sh** - Comprehensive validation and testing script
- **cleanup.sh** - Resource cleanup utility

## Configuration
- **LICENSE** - MIT License
- **VERSION** - Current version information
- **.gitignore** - Git ignore patterns

## Directories
- **.github/** - GitHub workflows and templates
- **test/** - Additional test configurations and examples

## Removed Files (Cleaned Up)
- `ec2nodeclass-dynamic.yaml` - Replaced by v3
- `ec2nodeclass-fixed.yaml` - Replaced by v3  
- `nodepool-dynamic.yaml` - Replaced by v3
- `nodepool-fixed.yaml` - Replaced by v3
- `test-*.yaml` - Temporary test files
