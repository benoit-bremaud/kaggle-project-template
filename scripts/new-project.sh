#!/usr/bin/env bash
# =============================================================================
# new-project.sh — Create a new Kaggle project from this template
#
# Usage:
#   bash scripts/new-project.sh <competition-name> [classic|agent]
#
# Examples:
#   bash scripts/new-project.sh titanic
#   bash scripts/new-project.sh sae-agent agent
#
# What it does:
#   1. Copies template files to ../kaggle-<competition>/
#   2. Replaces COMPETITION_NAME placeholders
#   3. Overlays agent-specific files (if TYPE=agent)
#   4. Initializes a git repository
#   5. Creates a public GitHub repository
#   6. Configures branch protection
#   7. Creates DS-oriented labels
# =============================================================================

set -euo pipefail

# --- Arguments ---------------------------------------------------------------

COMPETITION="${1:-}"
TYPE="${2:-classic}"

if [[ -z "$COMPETITION" ]]; then
    echo "Usage: bash scripts/new-project.sh <competition-name> [classic|agent]"
    echo ""
    echo "Examples:"
    echo "  bash scripts/new-project.sh titanic"
    echo "  bash scripts/new-project.sh sae-agent agent"
    exit 1
fi

if [[ "$TYPE" != "classic" && "$TYPE" != "agent" ]]; then
    echo "Error: TYPE must be 'classic' or 'agent' (got: '$TYPE')"
    exit 1
fi

# --- Paths -------------------------------------------------------------------

TEMPLATE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KAGGLE_DIR="$(dirname "$TEMPLATE_DIR")"
REPO_NAME="kaggle-${COMPETITION}"
DEST_DIR="${KAGGLE_DIR}/${REPO_NAME}"
GH_USER="$(git config user.name 2>/dev/null || echo 'benoit-bremaud')"
GH_USER="benoit-bremaud"  # explicit override — change if needed

# --- Colors ------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERR ]${NC} $1"; exit 1; }

# --- Pre-flight checks -------------------------------------------------------

echo ""
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  Creating Kaggle project: ${REPO_NAME} (${TYPE})${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

if ! command -v gh &> /dev/null; then
    error "gh CLI not found. Install from https://cli.github.com"
fi

if ! gh auth status &> /dev/null 2>&1; then
    error "gh CLI not authenticated. Run: gh auth login"
fi

if [[ -d "$DEST_DIR" ]]; then
    error "Directory already exists: $DEST_DIR"
fi

info "Template  : $TEMPLATE_DIR"
info "Destination: $DEST_DIR"
info "GitHub    : github.com/${GH_USER}/${REPO_NAME}"
echo ""

# --- Copy base template ------------------------------------------------------

info "Copying base template..."

rsync -a \
    --exclude='.git/' \
    --exclude='.venv/' \
    --exclude='__pycache__/' \
    --exclude='*.pyc' \
    --exclude='*.pyo' \
    --exclude='data/raw/*' \
    --exclude='data/processed/*' \
    --exclude='outputs/models/*' \
    --exclude='.ipynb_checkpoints/' \
    --exclude='scripts/' \
    --exclude='templates/' \
    --exclude='.claude/' \
    --exclude='.kaggle-competition' \
    "$TEMPLATE_DIR/" "$DEST_DIR/"

ok "Base template copied"

# --- Replace placeholders ----------------------------------------------------

info "Replacing COMPETITION_NAME placeholder..."

find "$DEST_DIR" -type f \( \
    -name "*.md" -o \
    -name "*.txt" -o \
    -name "*.toml" -o \
    -name "*.yml" -o \
    -name "*.yaml" -o \
    -name "*.sh" -o \
    -name "*.py" \
) -exec sed -i "s/COMPETITION_NAME/${COMPETITION}/g" {} +

# Update pyproject.toml project name
sed -i "s/name = \"kaggle-project\"/name = \"${REPO_NAME}\"/" "$DEST_DIR/pyproject.toml"

ok "Placeholders replaced"

# --- Overlay agent template --------------------------------------------------

if [[ "$TYPE" == "agent" ]]; then
    info "Applying agent template overlay..."

    AGENT_TEMPLATE="${TEMPLATE_DIR}/templates/agent"

    if [[ ! -d "$AGENT_TEMPLATE" ]]; then
        warn "templates/agent/ not found — skipping overlay"
    else
        rsync -a "$AGENT_TEMPLATE/" "$DEST_DIR/"
        ok "Agent template overlay applied"

        # Remove the classic data science notebook (replaced by exploration.ipynb)
        if [[ -f "$DEST_DIR/notebooks/notebook.ipynb" ]]; then
            rm "$DEST_DIR/notebooks/notebook.ipynb"
            ok "Removed classic notebook (replaced by exploration.ipynb)"
        fi
    fi
fi

# --- Git setup ---------------------------------------------------------------

info "Initializing git repository..."

cd "$DEST_DIR"
git init
git add .
git commit -m "chore(init): initialize project from kaggle-project-template

Project: ${REPO_NAME}
Type: ${TYPE}
Template: github.com/${GH_USER}/kaggle-project-template"

ok "Git repository initialized with first commit"

# --- Create GitHub repository ------------------------------------------------

info "Creating GitHub repository: ${GH_USER}/${REPO_NAME}..."

gh repo create "${GH_USER}/${REPO_NAME}" \
    --public \
    --source=. \
    --remote=origin \
    --push

ok "Repository created: https://github.com/${GH_USER}/${REPO_NAME}"

# --- Branch protection -------------------------------------------------------

info "Configuring branch protection on main..."

PROTECTION_PAYLOAD='{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "required_approving_review_count": 0
  },
  "restrictions": null
}'

if echo "$PROTECTION_PAYLOAD" | gh api \
    "repos/${GH_USER}/${REPO_NAME}/branches/main/protection" \
    --method PUT \
    --input - \
    -H "Accept: application/vnd.github+json" \
    --silent 2>/dev/null; then
    ok "Branch protection enabled (PRs required to merge)"
    warn "Note: Add required CI checks manually after the first workflow run"
else
    warn "Branch protection failed — configure manually in repo Settings > Branches"
fi

# --- Labels ------------------------------------------------------------------

info "Creating DS-oriented labels..."

create_label() {
    local name="$1" color="$2" description="$3"
    gh label create "$name" \
        --color "$color" \
        --description "$description" \
        --repo "${GH_USER}/${REPO_NAME}" \
        --force 2>/dev/null || true
}

# Delete default GitHub labels
for label in "bug" "documentation" "duplicate" "enhancement" "good first issue" "help wanted" "invalid" "question" "wontfix"; do
    gh label delete "$label" --repo "${GH_USER}/${REPO_NAME}" --yes 2>/dev/null || true
done

# Type labels
create_label "type:eda"          "0075ca" "Exploratory data analysis"
create_label "type:data-cleaning" "e4e669" "Data cleaning and preprocessing"
create_label "type:feature-eng"  "f9d0c4" "Feature engineering"
create_label "type:modeling"     "d93f0b" "Model training and tuning"
create_label "type:evaluation"   "0e8a16" "Model evaluation and metrics"
create_label "type:submission"   "1d76db" "Kaggle submission"
create_label "type:bug"          "d73a4a" "Bug fix"
create_label "type:refactor"     "fef2c0" "Code refactoring"
create_label "type:docs"         "c5def5" "Documentation"
create_label "type:setup"        "e4e669" "Project setup and configuration"
create_label "type:experiment"   "5319e7" "Experiment / exploration"

# Area labels
create_label "area:notebook"     "bfd4f2" "Jupyter notebooks"
create_label "area:src"          "bfdadc" "Source code (src/)"
create_label "area:data"         "dae8fc" "Data pipeline"
create_label "area:model"        "fbca04" "Model files"
create_label "area:infra"        "eeeeee" "Infrastructure / CI / tooling"

# Priority labels
create_label "priority:critical" "b60205" "Must fix immediately"
create_label "priority:high"     "d93f0b" "High priority"
create_label "priority:medium"   "e4e669" "Medium priority"
create_label "priority:low"      "0e8a16" "Low priority, nice to have"

# Status labels
create_label "status:blocked"       "e11d48" "Blocked by a dependency"
create_label "status:needs-review"  "7057ff" "Waiting for review"
create_label "status:wontfix"       "ffffff" "Will not be fixed"

# Meta
create_label "good-first-issue"  "7057ff" "Good for newcomers"

ok "Labels created"

# --- Summary -----------------------------------------------------------------

echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}  Project created successfully!${NC}"
echo -e "${GREEN}======================================================${NC}"
echo ""
echo "  Repository  : https://github.com/${GH_USER}/${REPO_NAME}"
echo "  Directory   : ${DEST_DIR}"
echo "  Type        : ${TYPE}"
echo ""
echo "Next steps:"
echo "  1. cd ${DEST_DIR}"

if [[ "$TYPE" == "agent" ]]; then
    echo "  2. cp .env.example .env"
    echo "     → Fill in ANTHROPIC_API_KEY and MAX_COST_USD"
    echo "  3. make setup"
    echo "  4. Read ARCHITECTURE.md to understand the agent structure"
    echo "  5. Add ANTHROPIC_API_KEY to GitHub Secrets:"
    echo "     gh secret set ANTHROPIC_API_KEY --repo ${GH_USER}/${REPO_NAME}"
else
    echo "  2. make setup"
    echo "  3. make data COMPETITION=${COMPETITION}"
    echo "  4. make notebook"
fi

echo ""
echo "  After your first CI run, enable required status checks:"
echo "  → Repo Settings > Branches > main > Edit > Require status checks"
echo "  → Add: 'Lint & Format' and 'Tests'"
echo ""
