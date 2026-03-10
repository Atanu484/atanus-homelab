#!/usr/bin/env bash
# Extract container image references from argocd/ YAML (Applications with Helm values,
# and raw K8s manifests). Output one image per line to stdout; empty if none.
set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}") && pwd)}"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
cd "$REPO_ROOT"

# Require yq (mikefarah/yq v4)
if ! command -v yq &>/dev/null; then
  echo "yq is required (install from https://github.com/mikefarah/yq)" >&2
  exit 1
fi

# Images we've already printed (dedupe)
declare -A SEEN

# Raw K8s manifest paths for container image
container_paths=(
  '.spec.template.spec.containers[].image'
  '.spec.containers[].image'
  '.spec.template.spec.initContainers[].image'
  '.spec.initContainers[].image'
)

# Emit image ref if not seen yet
emit() {
  local ref
  ref="$(echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "$ref" ]] && return
  # Must look like an image ref (has : or @, or at least one /)
  if [[ "$ref" =~ : ]] || [[ "$ref" =~ @ ]] || [[ "$ref" =~ / ]]; then
    if [[ -z "${SEEN[$ref]:-}" ]]; then
      SEEN[$ref]=1
      echo "$ref"
    fi
  fi
}

# Extract from a single YAML file (K8s container fields)
extract_k8s() {
  local f="$1"
  for path in "${container_paths[@]}"; do
    while IFS= read -r line; do
      emit "$line"
    done < <(yq eval --no-doc "$path" "$f" 2>/dev/null || true)
  done
}

# Parse Helm values string and output full image refs (repository:tag or registry/repository:tag)
extract_helm_values() {
  local values_yaml="$1"
  if [[ -z "$values_yaml" ]]; then
    return
  fi
  # Full image string: .. | .image? | select(type == "!!str")
  while IFS= read -r line; do
    emit "$line"
  done < <(echo "$values_yaml" | yq eval '.. | .image? | select(type == "!!str")' - 2>/dev/null || true)
  # repository + tag (and optional registry): objects under .image
  while IFS= read -r line; do
    emit "$line"
  done < <(
    echo "$values_yaml" | yq eval '
      [.. | objects | select(has("repository") and (.repository | type == "!!str")) |
        (if has("registry") and (.registry | type == "!!str") and .registry != "" then .registry + "/" else "" end) +
        .repository + ":" + ((.tag // .version // "latest") | to_string)
      ] | unique[]
    ' - 2>/dev/null || true
  )
}

# Extract from ArgoCD Application (single source or multi-source)
extract_app() {
  local f="$1"
  # Single source
  local values
  values="$(yq eval '.spec.source.helm.values // ""' "$f" 2>/dev/null)"
  extract_helm_values "$values"
  # Multi-source (sources array)
  local idx=0
  while true; do
    values="$(yq eval ".spec.sources[$idx].helm.values // \"\"" "$f" 2>/dev/null)"
    [[ -z "$values" || "$values" == "null" ]] && break
    extract_helm_values "$values"
    ((idx++)) || break
  done
}

# Main
for f in argocd/apps/*.yaml argocd/apps/*.yml; do
  [[ -f "$f" ]] || continue
  extract_k8s "$f"
  if yq eval '.kind == "Application"' "$f" 2>/dev/null | grep -qx true; then
    extract_app "$f"
  fi
done

# Nested manifests (e.g. glance-manifests, pmm-manifests)
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  extract_k8s "$f"
done < <(find argocd -type f \( -name '*.yaml' -o -name '*.yml' \) -path 'argocd/apps/*/*' 2>/dev/null || true)
