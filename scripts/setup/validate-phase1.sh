#!/usr/bin/env bash
# scripts/setup/validate-phase1.sh
# Run Phase 1 validation checks inside WSL / Linux.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "\n${CYAN}==========================================${NC}"
echo -e "${CYAN}  Phase 1 Validation — WSL / Linux${NC}"
echo -e "${CYAN}==========================================${NC}\n"

# 1. Tool check
echo -e "1. Tool Versions"
terraform version || { echo -e "${RED}Terraform not installed${NC}"; exit 1; }
aws --version || { echo -e "${YELLOW}AWS CLI not found (optional for static validation)${NC}"; }

# 2. Format check
echo -e "\n2. Terraform Formatting Check"
terraform fmt -check -recursive infrastructure/terraform/ || {
  echo -e "${YELLOW}Formatting issues detected. Running: terraform fmt -recursive infrastructure/terraform/${NC}"
  terraform fmt -recursive infrastructure/terraform/
}
echo -e "${GREEN}  [PASS] Terraform formatting clean${NC}"

# 3. Dev Environment Validation
echo -e "\n3. Validating Dev Environment"
cd infrastructure/terraform/environments/dev
terraform init -backend=false -reconfigure
terraform validate
echo -e "${GREEN}  [PASS] dev environment is valid!${NC}"
cd - > /dev/null

# 4. Showcase Environment Validation
echo -e "\n4. Validating Showcase Environment"
cd infrastructure/terraform/environments/showcase
terraform init -backend=false -reconfigure
terraform validate
echo -e "${GREEN}  [PASS] showcase environment is valid!${NC}"
cd - > /dev/null

# 5. Checkov static scan (if installed)
echo -e "\n5. Static Security Scan"
if command -v checkov &> /dev/null; then
  checkov -d infrastructure/terraform/ --framework terraform --config-file security/scans/checkov.yaml --quiet
  echo -e "${GREEN}  [PASS] Checkov scan passed${NC}"
else
  echo -e "${YELLOW}  [INFO] Checkov not installed. Run 'pip install checkov' to run security checks.${NC}"
fi

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}  All Terraform validations passed!${NC}"
echo -e "${GREEN}==========================================${NC}\n"

