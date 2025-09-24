# Terraform Makefile - Reusable automation for Terraform operations
# Project: Grafana Terraform Module for AKS with Azure AD OIDC

.DEFAULT_GOAL := help
.PHONY: help check init validate format plan apply destroy clean security docs test install-tools

# Configuration
TF_LOG_LEVEL ?= INFO
TF_VAR_FILE ?= terraform.tfvars
PLAN_FILE ?= tfplan
BACKUP_DIR := .terraform-backups
LOG_DIR := .terraform-logs
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Colors for output
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
BLUE := \033[34m
BOLD := \033[1m
RESET := \033[0m

# Helper function to print colored output
define print_status
	@echo "$(1)[$(2)]$(RESET) $(3)"
endef

# Create required directories
$(BACKUP_DIR) $(LOG_DIR):
	@mkdir -p $@

# Help target - displays available targets
help: ## Display available targets and their descriptions
	@echo "$(BOLD)Terraform Operations for Grafana AKS Module$(RESET)"
	@echo ""
	@echo "$(BOLD)Main Targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(BOLD)Configuration:$(RESET)"
	@echo "  TF_VAR_FILE=$(TF_VAR_FILE)    # Variable file to use"
	@echo "  PLAN_FILE=$(PLAN_FILE)      # Plan file name"
	@echo "  TF_LOG_LEVEL=$(TF_LOG_LEVEL)   # Terraform log level"
	@echo ""
	@echo "$(BOLD)Examples:$(RESET)"
	@echo "  make check                    # Full validation workflow"
	@echo "  make plan TF_VAR_FILE=dev.tfvars"
	@echo "  make apply PLAN_FILE=myplan"

# Prerequisites check
check-prereqs: ## Check if required tools are installed
	$(call print_status,$(BLUE),INFO,Checking prerequisites...)
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)ERROR: terraform not found$(RESET)"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "$(YELLOW)WARNING: kubectl not found$(RESET)"; }
	@terraform version
	$(call print_status,$(GREEN),SUCCESS,Prerequisites check completed)

# Install development tools
install-tools: ## Install helpful development tools
	$(call print_status,$(BLUE),INFO,Installing development tools...)
	@echo "Installing tfsec for security scanning..."
	@go install github.com/aquasecurity/tfsec/cmd/tfsec@latest 2>/dev/null || echo "$(YELLOW)WARNING: Failed to install tfsec (requires Go)$(RESET)"
	@echo "Installing terraform-docs for documentation..."
	@go install github.com/terraform-docs/terraform-docs@latest 2>/dev/null || echo "$(YELLOW)WARNING: Failed to install terraform-docs (requires Go)$(RESET)"
	$(call print_status,$(GREEN),SUCCESS,Tools installation completed)

# Backup state files
backup: | $(BACKUP_DIR) ## Backup current state and lock files
	$(call print_status,$(BLUE),INFO,Backing up state files...)
	@if [ -f "terraform.tfstate" ]; then \
		cp terraform.tfstate $(BACKUP_DIR)/terraform.tfstate.$(TIMESTAMP); \
		echo "State backed up to $(BACKUP_DIR)/terraform.tfstate.$(TIMESTAMP)"; \
	fi
	@if [ -f ".terraform.lock.hcl" ]; then \
		cp .terraform.lock.hcl $(BACKUP_DIR)/.terraform.lock.hcl.$(TIMESTAMP); \
		echo "Lock file backed up to $(BACKUP_DIR)/.terraform.lock.hcl.$(TIMESTAMP)"; \
	fi
	$(call print_status,$(GREEN),SUCCESS,Backup completed)

# Initialize Terraform
init: check-prereqs | $(LOG_DIR) ## Initialize Terraform with backend configuration
	$(call print_status,$(BLUE),INFO,Initializing Terraform...)
	@TF_LOG=$(TF_LOG_LEVEL) terraform init -upgrade 2>&1 | tee $(LOG_DIR)/init.$(TIMESTAMP).log
	$(call print_status,$(GREEN),SUCCESS,Terraform initialized successfully)

# Validate Terraform configuration
validate: ## Validate Terraform configuration syntax
	$(call print_status,$(BLUE),INFO,Validating Terraform configuration...)
	@terraform validate
	$(call print_status,$(GREEN),SUCCESS,Configuration is valid)

# Format Terraform files
format: ## Format Terraform files and check for changes
	$(call print_status,$(BLUE),INFO,Formatting Terraform files...)
	@if terraform fmt -recursive -diff; then \
		$(call print_status,$(GREEN),SUCCESS,All files properly formatted); \
	else \
		$(call print_status,$(YELLOW),WARNING,Some files were reformatted); \
	fi

# Security scanning
security: ## Run security scan with tfsec
	$(call print_status,$(BLUE),INFO,Running security scan...)
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec . --soft-fail || $(call print_status,$(YELLOW),WARNING,Security issues found but continuing); \
		$(call print_status,$(GREEN),SUCCESS,Security scan completed); \
	else \
		$(call print_status,$(YELLOW),WARNING,tfsec not found - run 'make install-tools'); \
	fi

# Generate documentation
docs: ## Generate module documentation with terraform-docs
	$(call print_status,$(BLUE),INFO,Generating documentation...)
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file README.md .; \
		$(call print_status,$(GREEN),SUCCESS,Documentation updated in README.md); \
	else \
		$(call print_status,$(YELLOW),WARNING,terraform-docs not found - run 'make install-tools'); \
	fi

# Create execution plan
plan: init validate format backup | $(LOG_DIR) ## Create Terraform execution plan
	$(call print_status,$(BLUE),INFO,Creating Terraform plan...)
	@if [ -f "$(TF_VAR_FILE)" ]; then \
		echo "Using variable file: $(TF_VAR_FILE)"; \
		TF_LOG=$(TF_LOG_LEVEL) terraform plan -var-file=$(TF_VAR_FILE) -out=$(PLAN_FILE) 2>&1 | tee $(LOG_DIR)/plan.$(TIMESTAMP).log; \
	else \
		echo "No variable file specified or $(TF_VAR_FILE) not found"; \
		TF_LOG=$(TF_LOG_LEVEL) terraform plan -out=$(PLAN_FILE) 2>&1 | tee $(LOG_DIR)/plan.$(TIMESTAMP).log; \
	fi
	$(call print_status,$(GREEN),SUCCESS,Plan created: $(PLAN_FILE))
	@echo "Review plan with: terraform show $(PLAN_FILE)"

# Apply changes
apply: backup | $(LOG_DIR) ## Apply Terraform changes (uses plan file if exists)
	$(call print_status,$(BLUE),INFO,Applying Terraform changes...)
	@if [ -f "$(PLAN_FILE)" ]; then \
		echo "Applying plan file: $(PLAN_FILE)"; \
		TF_LOG=$(TF_LOG_LEVEL) terraform apply $(PLAN_FILE) 2>&1 | tee $(LOG_DIR)/apply.$(TIMESTAMP).log; \
	else \
		echo "No plan file found, running interactive apply..."; \
		TF_LOG=$(TF_LOG_LEVEL) terraform apply 2>&1 | tee $(LOG_DIR)/apply.$(TIMESTAMP).log; \
	fi
	$(call print_status,$(GREEN),SUCCESS,Apply completed successfully)

# Apply with auto-approval (dangerous!)
apply-auto: backup | $(LOG_DIR) ## Apply changes with auto-approval (DANGEROUS)
	$(call print_status,$(YELLOW),WARNING,Auto-approving apply - no confirmation!)
	@TF_LOG=$(TF_LOG_LEVEL) terraform apply -auto-approve 2>&1 | tee $(LOG_DIR)/apply-auto.$(TIMESTAMP).log
	$(call print_status,$(GREEN),SUCCESS,Auto-apply completed)

# Destroy infrastructure
destroy: backup | $(LOG_DIR) ## Destroy all Terraform-managed resources
	$(call print_status,$(RED),WARNING,This will destroy ALL resources!)
	@TF_LOG=$(TF_LOG_LEVEL) terraform destroy 2>&1 | tee $(LOG_DIR)/destroy.$(TIMESTAMP).log
	$(call print_status,$(GREEN),SUCCESS,Destroy completed)

# Destroy with auto-approval (very dangerous!)
destroy-auto: backup | $(LOG_DIR) ## Destroy resources with auto-approval (VERY DANGEROUS)
	$(call print_status,$(RED),WARNING,Auto-approving destroy - ALL RESOURCES WILL BE DELETED!)
	@TF_LOG=$(TF_LOG_LEVEL) terraform destroy -auto-approve 2>&1 | tee $(LOG_DIR)/destroy-auto.$(TIMESTAMP).log
	$(call print_status,$(GREEN),SUCCESS,Auto-destroy completed)

# Full check workflow
check: init validate format security plan ## Run complete validation workflow
	$(call print_status,$(GREEN),SUCCESS,Full check workflow completed successfully)
	@echo ""
	@echo "$(BOLD)Next steps:$(RESET)"
	@echo "  - Review the plan: terraform show $(PLAN_FILE)"
	@echo "  - Apply changes: make apply"
	@echo "  - Check logs in: $(LOG_DIR)/"

# Test the module (if test configuration exists)
test: ## Run module tests (requires test configuration)
	$(call print_status,$(BLUE),INFO,Running module tests...)
	@if [ -d "test" ]; then \
		cd test && terraform init && terraform plan; \
		$(call print_status,$(GREEN),SUCCESS,Module tests passed); \
	else \
		$(call print_status,$(YELLOW),WARNING,No test directory found); \
	fi

# Clean up temporary files
clean: ## Clean up Terraform temporary files and logs
	$(call print_status,$(BLUE),INFO,Cleaning up temporary files...)
	@rm -rf .terraform/
	@rm -f .terraform.lock.hcl
	@rm -f tfplan*
	@rm -f *.tfplan
	@rm -f terraform.tfstate.backup
	@rm -f crash.log
	$(call print_status,$(GREEN),SUCCESS,Cleanup completed)

# Clean up everything including backups and logs
clean-all: clean ## Clean up everything including backups and logs
	$(call print_status,$(YELLOW),WARNING,Removing ALL temporary files, backups, and logs...)
	@rm -rf $(BACKUP_DIR) $(LOG_DIR)
	$(call print_status,$(GREEN),SUCCESS,Complete cleanup finished)

# Show current status
status: ## Show current Terraform and workspace status
	$(call print_status,$(BLUE),INFO,Current Terraform status:)
	@echo "Workspace: $$(terraform workspace show 2>/dev/null || echo 'Not initialized')"
	@echo "Version: $$(terraform version -json 2>/dev/null | jq -r '.terraform_version' || terraform version | head -n1)"
	@if [ -f "terraform.tfstate" ]; then \
		echo "State file: Present ($$(stat -c%s terraform.tfstate 2>/dev/null || stat -f%z terraform.tfstate 2>/dev/null || echo 'unknown') bytes)"; \
	else \
		echo "State file: Not found"; \
	fi
	@if [ -f ".terraform.lock.hcl" ]; then \
		echo "Lock file: Present"; \
	else \
		echo "Lock file: Not found"; \
	fi

# Example workflows for different environments
dev: ## Quick development workflow: check + plan
	@$(MAKE) check TF_VAR_FILE=dev.tfvars PLAN_FILE=dev.tfplan

staging: ## Staging workflow: check + plan with staging vars
	@$(MAKE) check TF_VAR_FILE=staging.tfvars PLAN_FILE=staging.tfplan

prod: ## Production workflow: full check + manual confirmation
	@$(MAKE) check TF_VAR_FILE=prod.tfvars PLAN_FILE=prod.tfplan
	$(call print_status,$(YELLOW),WARNING,Production plan ready - review carefully before applying!)

# Parallel operations (where safe)
parallel-check: ## Run validation checks in parallel
	$(call print_status,$(BLUE),INFO,Running parallel validation checks...)
	@$(MAKE) -j3 validate format security
	$(call print_status,$(GREEN),SUCCESS,Parallel checks completed)