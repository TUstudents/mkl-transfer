"""Minimal block2 DMRG smoke test based on the official Hubbard tutorial."""

import os
import tempfile

import numpy as np
from pyblock2.driver.core import DMRGDriver, SymmetryTypes

L = 8
N = 8
TWOSZ = 0
T = 1.0
U = 2.0
REFERENCE = -6.225634144662398
TOL = 1e-10

with tempfile.TemporaryDirectory(prefix="block2-smoke-") as scratch:
    driver = DMRGDriver(scratch=scratch, symm_type=SymmetryTypes.SZ, n_threads=4)
    driver.initialize_system(n_sites=L, n_elec=N, spin=TWOSZ)

    b = driver.expr_builder()
    hopping = np.array(
        [[[i, i + 1], [i + 1, i]] for i in range(L - 1)]
    ).flatten()
    b.add_term("cd", hopping, -T)
    b.add_term("CD", hopping, -T)
    b.add_term("cdCD", np.array([[i] * 4 for i in range(L)]).flatten(), U)

    mpo = driver.get_mpo(b.finalize(), iprint=0)
    ket = driver.get_random_mps(tag="KET", bond_dim=250, nroots=1)

    energy = float(
        driver.dmrg(
            mpo,
            ket,
            n_sweeps=20,
            bond_dims=[250] * 4 + [500] * 4,
            noises=[1e-4] * 4 + [1e-5] * 4 + [0],
            thrds=[1e-10] * 8,
            cutoff=0,
            iprint=0,
        )
    )

delta = abs(energy - REFERENCE)
print(f"energy={energy:.15f}")
print(f"reference={REFERENCE:.15f}")
print(f"abs_error={delta:.3e}")
if delta > TOL:
    raise SystemExit(f"block2 smoke test failed: |dE|={delta} > {TOL}")
print("block2 Hubbard smoke test PASSED")
