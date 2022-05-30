## 1.4.2

- Update dependencies:
  - use lint instead of pedantic
  - update prometheus_client to ^1.0.0

## 1.4.1

- add option to disable logging access

## 1.4.0

- send USR1 to traefik on file rotate

## 1.3.2

- fix docker env vars

## 1.3.1

- disable metrics on docker by default
- add `ENABLE_METRICS` (defaults to false) and `METRICS_PORT` (defaults to 8080) on docker

## 1.3.0

- add prometheus metrics

## 1.2.0

- add privateClientAddress

## 1.1.0

- Add geohash to location if possible.

## 1.0.0

- Initial version
