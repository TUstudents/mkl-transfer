#!/usr/bin/env bash
set -euo pipefail

WHEELHOUSE="${1:-wheelhouse}"
PYTHON="${PYTHON:-python}"

if [[ ! -d "$WHEELHOUSE" ]]; then
  echo "wheelhouse not found: $WHEELHOUSE" >&2
  exit 2
fi

# shellcheck disable=SC1091
source "$(dirname "$0")/runtime.env"

PYVER="$($PYTHON -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
ARCH="$(uname -m)"

if [[ "$PYVER" != "3.13" ]]; then
  echo "This pinned block2 wheel requires CPython 3.13; found $PYVER" >&2
  exit 3
fi

if [[ "$ARCH" != "x86_64" ]]; then
  echo "This pinned runtime requires Linux x86_64; found $ARCH" >&2
  exit 4
fi

for f in "$MKL_WHEEL" "$BLOCK2_WHEEL" "SHA256SUMS.txt"; do
  [[ -f "$WHEELHOUSE/$f" ]] || { echo "missing $WHEELHOUSE/$f" >&2; exit 5; }
done

(
  cd "$WHEELHOUSE"
  sha256sum -c SHA256SUMS.txt
)

# MKL's wheel declares optional packaging dependencies (intel-openmp, tbb,
# mkl-include) that are not needed by this GNU-threaded block2 binary.
"$PYTHON" -m pip install --no-deps --force-reinstall "$WHEELHOUSE/$MKL_WHEEL"
"$PYTHON" -m pip install --no-deps --force-reinstall "$WHEELHOUSE/$BLOCK2_WHEEL"

"$PYTHON" - <<'PY'
import ctypes
import os
import sys

prefix_lib = os.path.join(sys.prefix, "lib")
required = [
    "libmkl_core.so.2",
    "libmkl_intel_lp64.so.2",
    "libmkl_gnu_thread.so.2",
    "libmkl_avx2.so.2",
    "libmkl_avx512.so.2",
]
missing = [x for x in required if not os.path.exists(os.path.join(prefix_lib, x))]
if missing:
    raise SystemExit(f"MKL runtime missing from {prefix_lib}: {missing}")

import block2
print("block2 import OK:", block2.__file__)
print("MKL runtime OK:", prefix_lib)
PY
