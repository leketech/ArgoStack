#!/bin/bash

# Generate project documentation

set -e

echo "Generating project documentation..."

# Create docs directory if it doesn't exist
mkdir -p docs

# Generate table of contents
echo "Generating table of contents..."
{
  echo "# Project Documentation"
  echo ""
  echo "## Table of Contents"
  echo ""
  echo "- [Project Overview](#project-overview)"
  echo "- [Architecture](#architecture)"
  echo "- [Components](#components)"
  echo "- [Deployment](#deployment)"
  echo "- [Monitoring](#monitoring)"
  echo "- [Security](#security)"
  echo "- [Troubleshooting](#troubleshooting)"
} > docs/TOC.md

echo "Documentation generation completed!"
echo "Documentation files are available in the docs/ directory:"
echo "  - docs/complete-documentation.md - Complete project documentation"
echo "  - docs/TOC.md - Table of contents"