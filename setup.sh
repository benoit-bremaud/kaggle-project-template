#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check Python version
PYTHON_MIN="3.12"
PYTHON=$(command -v python3 || true)
if [[ -z "$PYTHON" ]]; then
    error "Python 3 not found. Please install Python >= $PYTHON_MIN"
fi

PYTHON_VERSION=$($PYTHON --version | cut -d' ' -f2)
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

if [[ "$PYTHON_MAJOR" -lt 3 ]] || [[ "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -lt 12 ]]; then
    error "Python >= $PYTHON_MIN required (found $PYTHON_VERSION)"
fi
ok "Python $PYTHON_VERSION detected"

# Create virtual environment
info "Creating virtual environment..."
if command -v uv &> /dev/null; then
    UV_MODE=true
    uv venv --python "$PYTHON"
    ok "Virtual environment created with uv"
else
    UV_MODE=false
    warn "uv not found, falling back to pip + venv"
    $PYTHON -m venv .venv
    ok "Virtual environment created with venv"
fi

# Activate venv for this script
source .venv/bin/activate

# Install dependencies
info "Installing dependencies..."
if [[ "$UV_MODE" == true ]]; then
    uv pip install -r requirements.txt
    uv pip install -r requirements-dev.txt
else
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install -r requirements-dev.txt
fi
ok "Dependencies installed"

# Configure pre-commit hooks
info "Setting up pre-commit hooks..."
if command -v pre-commit &> /dev/null; then
    pre-commit install
    ok "Pre-commit hooks installed"
else
    warn "pre-commit not found globally. Install with: pipx install pre-commit"
fi

# Configure nbstripout
info "Setting up nbstripout..."
if command -v nbstripout &> /dev/null; then
    nbstripout --install
    ok "nbstripout configured (notebook outputs will be stripped on commit)"
else
    warn "nbstripout not found globally. Install with: pipx install nbstripout"
fi

# Create .gitkeep files for empty directories
touch data/raw/.gitkeep data/processed/.gitkeep outputs/models/.gitkeep

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Download your competition data into data/raw/"
echo "  2. Run 'make notebook' to start Jupyter Lab"
echo "  3. Open notebooks/notebook.ipynb and start exploring!"
echo ""
echo "Useful commands:"
echo "  make notebook  - Start Jupyter Lab"
echo "  make lint      - Check code quality"
echo "  make format    - Format code"
echo "  make clean     - Clean temp files"
echo ""
