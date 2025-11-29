# 🚀 GitHub Actions CI/CD Pipeline Documentation

## Overview

This repository implements a comprehensive CI/CD pipeline using GitHub Actions, covering the complete software delivery lifecycle with advanced deployment strategies, security scanning, and compliance monitoring.

## 📁 Pipeline Structure

```
.github/workflows/
├── main-cicd-pipeline.yml          # Master CI/CD pipeline with change detection
├── canary-deployment.yml            # Canary deployment with traffic splitting  
├── blue-green-deployment.yml        # Blue-green deployment for zero downtime
├── emergency-rollback.yml           # Emergency rollback procedures
├── feature-branch-pipeline.yml      # Feature branch testing and deployment
└── security-compliance-pipeline.yml # Security scanning and compliance
```

## 🔄 Main CI/CD Pipeline (`main-cicd-pipeline.yml`)

**Triggers:** Push to `main` or `develop` branches

**Features:**
- ✅ **Smart Change Detection** - Only builds and deploys changed microservices
- ✅ **Multi-Service Support** - Handles 10 microservices independently
- ✅ **Automated Testing** - Unit tests, integration tests, quality checks
- ✅ **GCR Integration** - Builds and pushes Docker images to Google Container Registry
- ✅ **GKE Deployment** - Automated Kubernetes deployments with health checks
- ✅ **Rollback Capability** - Automatic rollback on deployment failures
- ✅ **Slack Notifications** - Real-time deployment status updates

### Workflow Steps:
1. **Change Detection** - Identifies modified services using git diff
2. **Quality Gate** - Runs tests, code quality checks, and security scans
3. **Image Building** - Builds Docker images for changed services
4. **Deployment** - Deploys to GKE with progressive rollout
5. **Health Verification** - Validates deployment health and readiness
6. **Notification** - Sends deployment status to Slack

### Environment Variables:
```yaml
GCP_PROJECT_ID: axiomatic-fiber-479102-k7
GCP_ZONE: us-central1-a
GKE_CLUSTER: ecommerce-cluster
REGISTRY: gcr.io
```

### Required Secrets:
- `GCP_SA_KEY` - Google Cloud Service Account key (JSON)
- `SLACK_WEBHOOK_URL` - Slack webhook for notifications

## 🐤 Canary Deployment (`canary-deployment.yml`)

**Triggers:** Manual workflow dispatch with parameters

**Features:**
- ✅ **Progressive Traffic Splitting** - 10% → 25% → 50% → 100%
- ✅ **Istio Integration** - Advanced traffic management with VirtualServices
- ✅ **Health Monitoring** - Continuous health checks during rollout
- ✅ **Performance Validation** - Load testing at each stage
- ✅ **Auto Promotion/Rollback** - Based on success criteria
- ✅ **Manual Gates** - Optional manual approval between stages

### Usage:
```yaml
# Manual trigger with parameters
workflow_dispatch:
  inputs:
    service: [api-gateway, user-service, product-service, ...]
    image_tag: latest
    auto_promote: true/false
```

### Canary Process:
1. **Deploy Canary** - Deploy new version alongside stable
2. **10% Traffic** - Route 10% traffic to canary
3. **Health Check** - Monitor metrics and errors
4. **25% Traffic** - Increase if healthy
5. **Performance Test** - Run load tests
6. **50% Traffic** - Continue progressive rollout
7. **Full Promotion** - Route 100% traffic to new version
8. **Cleanup** - Remove old version

## 🔵🟢 Blue-Green Deployment (`blue-green-deployment.yml`)

**Triggers:** Manual workflow dispatch for critical services

**Features:**
- ✅ **Zero Downtime** - Instant traffic switching
- ✅ **Full Environment Testing** - Complete validation before switch
- ✅ **Performance Benchmarking** - Load testing on green environment
- ✅ **Manual Approval Gates** - Optional manual traffic switch
- ✅ **Instant Rollback** - Quick revert to blue if issues occur

### Critical Services Supported:
- `api-gateway` - Main application gateway
- `user-service` - User management service  
- `payment-service` - Payment processing
- `order-service` - Order management

### Deployment Flow:
1. **Prepare Blue** - Label current production as "blue"
2. **Deploy Green** - Create new environment with updated image
3. **Validate Green** - Health checks, integration tests
4. **Performance Test** - Load testing on green environment
5. **Traffic Switch** - Route traffic to green (manual or auto)
6. **Monitor** - 5-minute monitoring period
7. **Cleanup** - Remove blue environment after verification

## 🚨 Emergency Rollback (`emergency-rollback.yml`)

**Triggers:** Manual workflow dispatch for production incidents

**Features:**
- ✅ **Multi-Service Rollback** - Rollback multiple services simultaneously
- ✅ **Previous Version Restore** - Automatic identification of last known good version
- ✅ **Health Verification** - Post-rollback health validation
- ✅ **Incident Management** - Automatic incident creation and notifications
- ✅ **Service Dependencies** - Handles service dependency order during rollback

### Emergency Response Flow:
1. **Incident Declaration** - Create incident record
2. **Service Selection** - Choose services to rollback
3. **Version Identification** - Find last stable versions
4. **Coordinated Rollback** - Rollback in dependency order
5. **Health Validation** - Verify system stability
6. **Notification** - Alert teams and stakeholders
7. **Post-Incident** - Generate rollback report

## 🌟 Feature Branch Pipeline (`feature-branch-pipeline.yml`)

**Triggers:** Push to `feature/*`, `hotfix/*`, `bugfix/*` branches and Pull Requests

**Features:**
- ✅ **Change Detection** - Only processes modified services
- ✅ **Quality Gates** - Comprehensive code quality checks
- ✅ **Security Scanning** - OWASP dependency check, SpotBugs, Checkstyle
- ✅ **Feature Environments** - Isolated testing environments per branch
- ✅ **Integration Testing** - Full integration test suite
- ✅ **PR Comments** - Automatic environment info in pull requests
- ✅ **Auto Cleanup** - Removes old feature environments after 24 hours

### Quality Checks:
- **Checkstyle** - Code style and formatting
- **SpotBugs** - Static analysis for potential bugs
- **OWASP Dependency Check** - Security vulnerability scanning
- **Unit Tests** - With 80% coverage requirement
- **Integration Tests** - Full service integration validation

### Feature Environment:
Each feature branch gets its own Kubernetes namespace:
```
Namespace: feature-{branch-name}
Services: Only modified services + dependencies
Access: Port-forward commands provided
Cleanup: Automatic after 24 hours
```

## 🛡️ Security & Compliance Pipeline (`security-compliance-pipeline.yml`)

**Triggers:** Daily schedule (2 AM UTC), push to main/develop, manual dispatch

**Features:**
- ✅ **Dependency Scanning** - OWASP dependency check for all services
- ✅ **Image Security** - Trivy container image vulnerability scanning
- ✅ **Kubernetes Security** - Kubesec, Polaris configuration auditing
- ✅ **Secrets Scanning** - TruffleHog for exposed secrets
- ✅ **Compliance Assessment** - OWASP Top 10, CIS Kubernetes Benchmark
- ✅ **Automated Reporting** - Comprehensive security dashboards

### Security Scans:

#### Dependency Security:
- **OWASP Dependency Check** - Known vulnerability database
- **Snyk Security** - Commercial vulnerability scanning
- **Custom Suppressions** - False positive management

#### Image Security:
- **Trivy Scanning** - Container image vulnerabilities
- **SARIF Upload** - GitHub Security tab integration
- **Multi-format Reports** - JSON, HTML, SARIF outputs

#### Kubernetes Security:
- **Kubesec** - Kubernetes manifest security scoring
- **Polaris** - Configuration best practices audit
- **CIS Benchmark** - Cluster security assessment
- **Network Policies** - Network segmentation validation

#### Compliance Standards:
- **OWASP Top 10** - Web application security risks
- **CIS Kubernetes Benchmark** - Container orchestration security
- **SOC 2 Type II** - Security, availability, integrity controls
- **ISO 27001** - Information security management
- **PCI DSS** - Payment card industry standards (if applicable)

## 🔧 Setup Instructions

### 1. Google Cloud Platform Setup

#### Service Account Creation:
```bash
# Create service account
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Service Account"

# Get service account email
SA_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:GitHub Actions Service Account" \
  --format="value(email)")

# Grant necessary permissions
gcloud projects add-iam-policy-binding axiomatic-fiber-479102-k7 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding axiomatic-fiber-479102-k7 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.clusterAdmin"

gcloud projects add-iam-policy-binding axiomatic-fiber-479102-k7 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=${SA_EMAIL}
```

### 2. GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

```
Repository Settings → Secrets and Variables → Actions → New repository secret
```

#### Required Secrets:
- **`GCP_SA_KEY`** - Contents of `github-actions-key.json`
- **`SLACK_WEBHOOK_URL`** - Slack webhook for notifications
- **`SNYK_TOKEN`** - Snyk API token for security scanning

#### Optional Secrets:
- **`DOCKER_USERNAME`** - Docker Hub username (if using Docker Hub)
- **`DOCKER_PASSWORD`** - Docker Hub password (if using Docker Hub)

### 3. Slack Integration Setup

#### Create Slack Webhook:
1. Go to https://api.slack.com/apps
2. Create new app → From scratch
3. Choose workspace and app name
4. Go to Incoming Webhooks
5. Activate and create webhook
6. Copy webhook URL to GitHub secrets

#### Slack Notifications Include:
- 📦 **Deployment Status** - Success/failure notifications
- 🚀 **Pipeline Execution** - Real-time pipeline updates  
- 🛡️ **Security Alerts** - Vulnerability findings
- 📊 **Performance Metrics** - Deployment performance data
- 🚨 **Emergency Alerts** - Rollback and incident notifications

### 4. Environment Configuration

#### GitHub Environments:
Create the following environments in GitHub repository settings:

1. **`production`** - Main production environment
   - Required reviewers for manual approvals
   - Deployment protection rules

2. **`feature-development`** - Feature branch deployments
   - Automatic deployments allowed
   - No approval required

3. **`production-manual-approval`** - Manual production deployments
   - Required reviewers for sensitive deployments
   - Deployment protection rules with timer

## 📊 Monitoring and Observability

### Pipeline Metrics:
- **Build Success Rate** - Percentage of successful builds
- **Deployment Frequency** - Number of deployments per day/week
- **Lead Time** - Time from commit to production
- **Mean Time to Recovery** - Time to recover from failures
- **Change Failure Rate** - Percentage of deployments causing issues

### Security Metrics:
- **Vulnerability Density** - Number of vulnerabilities per service
- **Security Scan Coverage** - Percentage of components scanned
- **Mean Time to Patch** - Time to remediate vulnerabilities
- **Compliance Score** - Overall security compliance percentage

### Available Dashboards:
- **GitHub Actions** - Built-in workflow execution metrics
- **Grafana** - Custom CI/CD and security dashboards
- **Slack** - Real-time notifications and alerts
- **Security Reports** - Downloadable compliance reports

## 🚨 Troubleshooting Guide

### Common Issues:

#### 1. GCP Authentication Failures
```bash
# Verify service account permissions
gcloud auth activate-service-account --key-file=github-actions-key.json
gcloud container clusters get-credentials ecommerce-cluster --zone=us-central1-a
```

#### 2. Docker Build Failures
```bash
# Check Dockerfile syntax
docker build -t test-image .

# Verify base image availability
docker pull openjdk:17-jdk-slim
```

#### 3. Kubernetes Deployment Issues
```bash
# Check cluster connectivity
kubectl cluster-info

# Verify namespace exists
kubectl get namespaces

# Check pod status
kubectl get pods -n dev
kubectl describe pod <pod-name> -n dev
```

#### 4. Maven Build Failures
```bash
# Clean and rebuild
./mvnw clean install -DskipTests

# Check for dependency conflicts
./mvnw dependency:tree
```

### Debug Mode:
Enable workflow debug logging:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## 📈 Best Practices

### 1. Security:
- ✅ Use least privilege service accounts
- ✅ Rotate secrets regularly
- ✅ Enable vulnerability scanning
- ✅ Implement secret scanning
- ✅ Use signed container images

### 2. Performance:
- ✅ Cache Maven dependencies
- ✅ Use parallel job execution
- ✅ Optimize Docker layer caching
- ✅ Minimize workflow artifact sizes

### 3. Reliability:
- ✅ Implement proper error handling
- ✅ Use appropriate timeout values
- ✅ Add retry logic for transient failures
- ✅ Monitor pipeline success rates

### 4. Maintainability:
- ✅ Use reusable workflow components
- ✅ Document all configuration
- ✅ Version control pipeline changes
- ✅ Regular pipeline health checks

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs)
- [Istio Service Mesh](https://istio.io/latest/docs/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)

## 🤝 Contributing

When contributing to the CI/CD pipelines:

1. **Test Changes** - Test pipeline changes in feature branches
2. **Documentation** - Update this README for any pipeline modifications
3. **Security Review** - Security team review for security-related changes
4. **Gradual Rollout** - Implement changes gradually across services

## 📝 Change Log

### Version 2.0.0 - Current
- ✅ Added canary deployment pipeline
- ✅ Implemented blue-green deployment
- ✅ Enhanced security scanning
- ✅ Added compliance assessment
- ✅ Feature branch environments
- ✅ Emergency rollback procedures

### Version 1.0.0 - Initial
- ✅ Basic CI/CD pipeline
- ✅ Docker image building
- ✅ Kubernetes deployment
- ✅ Basic notifications

---

**Pipeline Grade Coverage**: 15% of final project (Estrategias de Despliegue y CI/CD)

**Maintained by**: DevOps Team  
**Last Updated**: $(date)  
**Status**: ✅ Production Ready