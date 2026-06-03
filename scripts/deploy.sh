#!/bin/bash
# =============================================================
# Deploy script for CI/CD GitOps Pipeline
# This script deploys the application using Helm
# =============================================================

set -e  # Exit on any error
set -o pipefail  # Catch pipeline errors

# ==============================
# Configuration variables
# ==============================
APP_NAME="${APP_NAME:-gitops-app}"
NAMESPACE="${NAMESPACE:-production}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
HELM_CHART_PATH="${HELM_CHART_PATH:-./helm}"
STAGING_NAMESPACE="${STAGING_NAMESPACE:-staging}"
PROD_NAMESPACE="${PROD_NAMESPACE:-production}"

echo "========================================"
echo "GitOps Deployment Script"
echo "========================================"
echo "App Name  : $APP_NAME"
echo "Namespace : $NAMESPACE"
echo "Image Tag : $IMAGE_TAG"
echo "Chart Path: $HELM_CHART_PATH"
echo "========================================"

# ==============================
# Function: Check prerequisites
# ==============================
check_prerequisites() {
    echo "Checking prerequisites..."

    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        echo "ERROR: helm is not installed!"
        exit 1
    fi

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo "ERROR: kubectl is not installed!"
        exit 1
    fi

    echo "All prerequisites are available."
}

# ==============================
# Function: Deploy to Kubernetes
# ==============================
deploy() {
    local environment=$1
    local namespace=$2
    local values_file=$3

    echo ""
    echo "Deploying to $environment..."
    echo "Namespace: $namespace"

    # Create namespace if it doesn't exist
    kubectl get namespace "$namespace" &> /dev/null || \
        kubectl create namespace "$namespace"

    # Deploy using Helm
    helm upgrade --install "$APP_NAME" "$HELM_CHART_PATH" \
        --namespace "$namespace" \
        --values "$values_file" \
        --set "image.tag=$IMAGE_TAG" \
        --wait \
        --timeout 5m

    echo "Successfully deployed to $environment!"
}

# ==============================
# Function: Verify deployment
# ==============================
verify_deployment() {
    local namespace=$1

    echo ""
    echo "Verifying deployment in $namespace..."

    # Wait for rollout to complete
    kubectl rollout status "deployment/$APP_NAME" \
        --namespace "$namespace" \
        --timeout=5m

    echo "Deployment verified successfully!"
}

# ==============================
# Main deployment flow
# ==============================
main() {
    check_prerequisites

    case "$1" in
        staging)
            deploy "Staging" "$STAGING_NAMESPACE" "helm/values-staging.yaml"
            verify_deployment "$STAGING_NAMESPACE"
            ;;
        production)
            deploy "Production" "$PROD_NAMESPACE" "helm/values.yaml"
            verify_deployment "$PROD_NAMESPACE"
            ;;
        *)
            echo "Usage: $0 [staging|production]"
            exit 1
            ;;
    esac

    echo ""
    echo "Deployment complete!"
}

# Run main function
main "$@"
