# ``NetworkingMiddlePinning``

Opt-in SSL certificate pinning for NetworkingMiddle.

## Overview

`NetworkingMiddlePinning` adds MITM-attack protection to any provider built with `NetworkingMiddle`.
It is a separate, Apple-platform-only import — existing code that does not import it is completely unaffected.

Pinning is implemented as **public-key pinning** (SPKI SHA-256), not raw certificate pinning, so a pinned host survives a certificate renewal as long as the same RSA/EC key-pair is kept.

## Topics

### Getting started

- <doc:Usage>

### Core types

- ``CertificatePinningPolicy``
- ``PinnedURLSession``

### Errors

- ``NetworkingMiddle/APIError/certificatePinningFailed(_:)``
