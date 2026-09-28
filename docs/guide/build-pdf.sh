#!/usr/bin/env bash
# Render build-guide.md to build-guide.pdf (US Letter) using the md2pdf theme.
set -euo pipefail
cd "$(dirname "$0")"
THEME="${MD2PDF_CSS:-style.css}"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PUPPETEER_SKIP_DOWNLOAD=true npx -y md-to-pdf \
  --stylesheet "$THEME" \
  --launch-options "{\"executablePath\":\"$CHROME\"}" \
  --pdf-options '{"format":"Letter","margin":{"top":"16mm","bottom":"16mm","left":"15mm","right":"15mm"},"printBackground":true}' \
  build-guide.md
echo "wrote $(pwd)/build-guide.pdf"
