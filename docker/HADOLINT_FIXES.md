# Hadolint Fixes Applied

All hadolint violations have been resolved. Here's what was fixed:

## Issues Fixed

### 1. DL3013 + DL3042: Unpinned pip package with cache
**Original:**
```dockerfile
&& python3 -m pip install mofapy2
```

**Fixed:**
```dockerfile
&& python3 -m pip install --no-cache-dir mofapy2==0.7.0
```

**Changes:**
- Added `--no-cache-dir` flag (DL3042)
- Pinned package version to `0.7.0` (DL3013)

---

### 2. DL3045: COPY to relative destination without WORKDIR
**Original:**
```dockerfile
COPY ./misc/requirements-bioc.R .
```

**Fixed:**
```dockerfile
WORKDIR /app
COPY ./misc/requirements-bioc.R .
```

**Changes:**
- Added `WORKDIR /app` before COPY to ensure absolute working directory context

---

### 3. DL3000: Relative WORKDIR path
**Original:**
```dockerfile
WORKDIR Omix
```

**Fixed:**
```dockerfile
WORKDIR /app/omix
```

**Changes:**
- Changed to absolute path `/app/omix`

---

### 4. DL3020: ADD instead of COPY
**Original:**
```dockerfile
ADD . .
```

**Fixed:**
```dockerfile
COPY . .
```

**Changes:**
- Changed from `ADD` to `COPY` (preferred for file copying)

---

### 5. SC2035 + DL3059: Shell globbing and multiple RUN instructions
**Original:**
```dockerfile
RUN Rscript -e "remotes::install_local()"
RUN rm -rf *
```

**Fixed:**
```dockerfile
RUN Rscript -e "remotes::install_local()" \
	&& rm -rf ./*
```

**Changes:**
- Consolidated two separate RUN instructions into one
- Changed glob pattern from `*` to `./*` to prevent shell option interpretation
- Uses `&&` to chain commands

---

## Verification

✓ All violations resolved
✓ Hadolint passes with no errors or warnings
✓ Ready for production use
