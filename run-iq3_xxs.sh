#!/bin/sh
# Start the tuned Strata model (IQ3_XXS, 3-GPU layer split) in the foreground.
# Close this window (Ctrl+C) to stop the model. Needs $HOME/strata-work/Strata
# set up (engine built, model prepared) - see README.md.
ROOT="$HOME/strata-work/Strata"
cd "$ROOT" || exit 1
exec "$ROOT/.venv/bin/python" "$ROOT/serve/server.py" \
  --engine strata --config "$ROOT/strata-iq3_xxs.json" --port 8080
