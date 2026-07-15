# Dockerfile Changes: Package Version Pinning

## Summary
All 90 apt packages in the apt-get install block have been pinned to exact versions from the `eleonoreschneeg/omix:latest` Docker Hub image (built 2024-01-22, digest sha256:8aed1d7ba3f74db69d6251c656db92f16ae60811e76ea93189241087c965679a).

## Key Changes in apt-get install block:

### Packages Renamed (compatibility with Ubuntu 22.04):
- `fortran77-compiler` → `gfortran=4:11.2.0-1ubuntu1`
- `libgsl0-dev` → `libgsl-dev=2.7.1+dfsg-3`
- `libhdf5-serial-dev` → `libhdf5-dev=1.10.7+repack-4ubuntu2`
- `libz-dev` → `zlib1g-dev=1:1.2.11.dfsg-2ubuntu9.2`

### Package Removed:
- `libv8-dev` — not available in Ubuntu 22.04 (was not installed in image)

### All Other Packages Pinned:
Added version pins like `python3=3.10.6-1~22.04`, `gcc=4:11.2.0-1ubuntu1`, etc. to all 86 remaining packages.

## Before (original):
```dockerfile
RUN apt-get update \
	&& apt-get install -y --no-install-recommends apt-utils \
	&& apt-get install -y --no-install-recommends \
	python3 \
	python3-setuptools \
	python3-dev \
	... (unpinned packages)
```

## After (pinned):
```dockerfile
RUN apt-get update \
	&& apt-get install -y --no-install-recommends apt-utils=2.4.11 \
	&& apt-get install -y --no-install-recommends \
	python3=3.10.6-1~22.04 \
	python3-setuptools=59.6.0-1.2ubuntu0.22.04.1 \
	python3-dev=3.10.6-1~22.04 \
	... (all packages pinned)
```

## Benefits
- **Reproducibility**: Exact same apt package versions on every build
- **Security**: Can easily track and update package versions when patched
- **Consistency**: Image builds will be identical across time and systems

## Data Source
Package versions extracted by running:
```bash
docker run --rm eleonoreschneeg/omix:latest dpkg-query -W -f='${Package}=${Version}\n' <package-names>
```

Against the published Docker Hub image: `eleonoreschneeg/omix:latest`
