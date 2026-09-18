# Security Policy

## Supported Versions

Security reports are evaluated against the `main` branch and the latest
release. Fixes are normally developed on `main` and included in a future
release when appropriate.

This project does not promise support for older releases, backports, or a
specific response or remediation time. Reports will be reviewed as maintainer
availability permits.

## Reporting a Vulnerability

Do not open a public Issue for a suspected security vulnerability.

Use GitHub's private vulnerability reporting for this repository by selecting
**Report a vulnerability** on the [repository's Security page](https://github.com/goroyabu/ugs/security). Include enough
information to understand and reproduce the concern when possible, such as:

- the affected version or commit;
- the relevant build or installation configuration;
- reproduction steps or a minimal input;
- the observed and expected behavior;
- the potential impact; and
- any suggested mitigation or fix.

Remove secrets, credentials, and unrelated private data from reports and logs.

The report may be accepted for further investigation, returned with questions,
or declined if it is not a security issue. Ordinary defects and feature
requests may be redirected to the public Issue tracker.

## Scope

Relevant reports may concern repository-maintained behavior such as:

- upstream archive acquisition and integrity verification;
- CMake build, installation, and package metadata;
- CI and release workflows;
- the installed UGS library as packaged here; and
- repository-specific changes to upstream sources or generated artifacts.

Reports involving downloaded upstream UGS code are welcome for
initial triage. If a concern originates entirely upstream, the reporter may be
asked to coordinate with the upstream project. This repository cannot promise
an upstream fix or timetable.

After a report is evaluated, disclosure and any GitHub Security Advisory will
be coordinated when appropriate. Submitting a report does not guarantee that
an advisory or CVE will be published.
