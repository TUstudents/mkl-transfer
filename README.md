# Persistent block2 runtime for ChatGPT containers

This repository keeps a reproducible **Linux x86_64 / CPython 3.13** block2 runtime outside any individual ChatGPT container.

## Pinned runtime

- block2 **0.5.4rc18**, CPython 3.13, Linux x86_64
- Intel MKL **2024.2.2**
- GitHub Release tag: **block2-runtime-v1**
- SHA-256 values are pinned in `runtime.env` and verified by CI.

MKL 2024.2.2 is intentional: this block2 wheel links to the MKL `.so.2` ABI. Newer MKL 2026 wheels use `.so.3` and are not a drop-in replacement.

## Restore in a future ChatGPT chat

Tell ChatGPT:

> Rehydrate block2 from TUstudents/mkl-transfer. Trigger the rehydrate workflow by updating rehydrate-trigger, download the block2-runtime-wheelhouse Actions artifact, extract it, run ./install-block2.sh <wheelhouse>, and run python smoke_test.py.

The workflow at `.github/workflows/rehydrate-runtime.yml` copies the permanent GitHub Release assets into a short-lived Actions artifact. This matters because the GitHub connector can reliably materialize Actions artifacts into a fresh ChatGPT container.

## Manual local restore

Download the three assets from release `block2-runtime-v1` into a directory called `wheelhouse`:

- `mkl-2024.2.2-py2.py3-none-manylinux1_x86_64.whl`
- `block2-0.5.4rc18-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl`
- `SHA256SUMS.txt`

Then run:

```bash
./install-block2.sh wheelhouse
python smoke_test.py
```

The smoke test runs the 8-site, half-filled 1D Hubbard DMRG example from the official block2 tutorial and checks the ground-state energy near `-6.225634144662398`.

## Updating the pinned runtime

Edit `runtime.env`. A change to that file triggers `.github/workflows/publish-runtime.yml`, which downloads both upstream wheels, verifies their pinned checksums, and creates or updates the durable GitHub Release.

Do not replace MKL independently without checking the shared-library ABI required by the block2 wheel.
