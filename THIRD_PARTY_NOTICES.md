# Third-Party Notices and Provenance

This repository maintains build, packaging, compatibility, test, and
documentation work around the upstream Unified Graphics System (UGS). This
document records the provenance and notices that could be verified from the
pinned upstream archive and primary historical material. It does not infer
rights that are not stated by those sources.

## License Boundary

The repository's [MIT License](LICENSE) applies to repository-maintained work
to the extent that the repository owner has the right to license it. It does
not relicense downloaded UGS sources, files derived from those sources,
embedded third-party components, generated sources, or artifacts compiled from
them. Those materials remain subject to their applicable upstream terms.

The Xlib smoke harness under `tests/cases/01_smoke/` is independently
repository-maintained and does not compile or incorporate upstream UGS source
files. Its visual reference under `tests/cases/03_visual_smoke/` is output from
that harness. Tests that link `ugs`, including `02_tryxw`, still build and use
the upstream material through the library boundary described above.

## Pinned Upstream Input

The build obtains `ugs.tar.gz` from the
[RIKEN Nishina Center mirror](https://ftp.riken.jp/iris/ugs/ugs.tar.gz) unless
a user supplies the same pinned input locally. The repository verifies this
archive with SHA256:

```text
27bc46e975917bdf149e9ff6997885ffa24b0b1416bdf82ffaea5246b36e1f83
```

The archive contains UGS 2.10e. It does not contain a top-level `LICENSE`,
`COPYING`, or equivalent comprehensive grant for the UGS distribution.

## Verified Lineage

The following lineage is supported by the archive documentation and the
[SLAC UGS internal operation and maintenance manual](https://www.slac.stanford.edu/vault/collvault/greylit/cgtm/CGTM205.pdf):

- Robert C. Beach and the Computation Research Group at the Stanford Linear
  Accelerator Center developed the original Unified Graphics System. The SLAC
  manual records that development began in 1972.
- The archive's `README.orig`, dated July 29, 1994, identifies UGS 2.10d as
  A. E. Kreymer's Unix port of the SLAC VMS version for use with Topdrawer at
  Fermilab.
- The archive's `README` identifies Hiroyuki Okamura and Osaka University's
  Research Center for Nuclear Physics (RCNP), and describes the additional
  Linux-oriented work that produced UGS 2.10e.
- The [RIKEN `iris` mirror](https://ftp.riken.jp/iris/) states that the tree was
  mirrored from an RCNP distribution site. Its
  [historical UGS area](https://ftp.riken.jp/iris/OLD/ugs/binaries/) also
  contains source and binary RPMs. A 2.10d source RPM labels the material
  `Copyright: Free`, but provides no corresponding terms that define that
  label. This metadata is historical provenance, not a comprehensive license
  grant.

## xvertext

The upstream archive includes `drivers/rotated.c`, derived from xvertext 5.0,
with this notice:

```text
xvertext 5.0, Copyright (c) 1993 Alan Richardson
(mppa3@uk.ac.sussex.syma)

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the above copyright notice appear in all copies and that both the
copyright notice and this permission notice appear in supporting
documentation. All work developed as a consequence of the use of this
program should duly acknowledge such use. No representations are made about
the suitability of this software for any purpose. It is provided "as is"
without express or implied warranty.
```

The build compiles this component into `libugs.a` as part of the upstream UGS
implementation. The repository-owned Xlib smoke harness does not compile or
link it.

## Font Data

The 2.10e `README` says the DUPLEX font uses UBCFONT with local extensions and
describes its glyph source as Alan V. Hershey's vector-font database published
in National Bureau of Standards Special Publication 424. No separate license
or permission notice for UBCFONT or the included Hershey-derived data was
found in the pinned archive. This section records provenance only.

## Unresolved Upstream Terms

No comprehensive permission notice for the UGS core, the FNAL Unix port, the
RCNP Linux changes, UBCFONT, or the included Hershey-derived data was found in
the pinned archive or the reviewed SLAC historical material. Historical public
availability, including source and binary RPMs, is not treated here as a
substitute for stated terms.

The repository downloads and builds the pinned archive but does not publish
that archive or attach prebuilt UGS libraries to its releases. Anyone
redistributing upstream sources or compiled artifacts such as `libugs.a`
should preserve applicable notices and independently confirm that the intended
use and distribution are permitted.

## Installed Files

The CMake install step installs the library and its package configuration; it
does not install this document or the repository's MIT License. Releases are
source-only, so both documents accompany the supported distribution from
which a local install is built. Reconsider notice installation or package
inclusion before adding CPack, operating-system packages, prebuilt libraries,
or other binary distribution.
