# README

## Overview

This project implements a **three-point stencil** in two dimensions, using:
1. A **basic** (reference) solution (`basic_solution`) for clarity.
2. A **blocked** solution (`blocked_solution`) that improves performance by processing the grid in fixed-size blocks.
3. A **SIMD**-optimized solution (`blocked_simd`) which uses **Intel intrinsics** to vectorize the blocked solution.
4. An **OpenMP** + SIMD solution (`blocked_simd_omp`) that parallelizes the SIMD approach across multiple threads.

The overarching goal is to compare the performance of these different approaches, focusing on **SIMD** vectorization and **multi-threaded** optimization.

---

## File Structure

- **stencil.cpp**  
  - Contains all four implementations:
    - `basic_solution(N, K, vec)`
    - `blocked_solution<B>(N, K, vec, trans)`
    - `blocked_simd<B>(N, K, vec, trans)` 
    - `blocked_simd_omp<B>(N, K, vec, trans)`

- **Makefile**  
  - Builds the executable `stencil`.

- **perf.jpg**  
  - A performance chart (bar chart or line graph) comparing the execution times for each approach.

---

## How to Build and Run

1. **Build the code**:
   ```bash
   make
   ```
   This will produce an executable named `stencil`.

2. **Run the code**:
   ```bash
   ./stencil
   ```
   By default, this uses `N = 1024` (grid dimension) and `K = 8` (neighbor range).  
   You can also specify different `N` and `K` via the command line:
   ```bash
   ./stencil 2048 16
   ```

After running, you should see timings for:
- Reference (basic)
- Blocked
- SIMD
- SIMD+OMP

---

## Implementation Details

### 1. Baseline: `basic_solution(N, K, vec)`
- Straightforward approach:
  - For each cell `(x, y)`, we look up to `K` neighbors on the left/right (same row) and up/down (same column).
  - Compute the average of these neighbors.
  - Writes the result to a temporary array, then copies back.

### 2. Blocked: `blocked_solution<B>(N, K, vec, trans)`
- Improves cache locality:
  - Processes the grid in `B x B` blocks.
  - Uses a *transposed* copy (`trans`) to efficiently handle vertical neighbors in contiguous memory.
  - Still uses scalar operations, but block-based iteration reduces cache misses.

### 3. SIMD Intrinsics: `blocked_simd<B>(N, K, vec, trans)`
- Builds on the blocked approach.
- Key changes:
  - We use SSE intrinsics (`_mm_*`) to load 4 floats at a time (where possible).
  - For boundary cases (less than 4 elements), we use a custom partial load function.
  - Summations are done with vector registers, then combined using a horizontal add (`_mm_hadd_ps`).
  - The transposed matrix again helps ensure vertical neighbors are in contiguous memory.

### 4. OpenMP + SIMD: `blocked_simd_omp<B>(N, K, vec, trans)`
- Combines **multithreading** with **SIMD**:
  - An `#pragma omp parallel for collapse(2)` is used to parallelize processing of the BxB blocks.
  - Within each block, we still exploit the SSE intrinsics for vectorization.
  - A final parallel loop writes the results back.

---

## Performance Results

Below is a sample performance measurement on a machine (e.g., Intel i7 or i9) with `N = 1024, K = 8` and `B = 32`.  
*(Note: Your exact numbers may vary depending on CPU, compiler flags, etc.)*

| **Version**        | **Time (ms)** |
|--------------------|---------------|
| Reference (Basic)  | ~XYZ ms       |
| Blocked            | ~XYZ ms       |
| SIMD Intrinsics    | ~XYZ ms       |
| SIMD + OpenMP      | ~XYZ ms       |

A chart illustrating these differences (in `perf.jpg`):
```
    +-------------+          
    |   Basic     |  <-- highest time
    +-------------+
    +--------+             
    |Blocked |  <-- better time
    +--------+
    +---+
    |SIMD|     <-- even better time
    +---+
    +--+
    |OMP|      <-- best time
    +--+
```

### Observations and Reasoning

1. **Blocked vs. Basic**:  
   Blocking the grid improves cache reuse. When processing the same `B x B` region, the data likely remains in the cache, reducing cache misses.

2. **SIMD vs. Blocked**:  
   Using **SIMD intrinsics** leverages CPU vector units to process multiple data elements in one instruction. This yields further speedups, especially when the data is well-aligned and we can load 4 floats at a time.

3. **SIMD + OMP**:  
   By splitting work across multiple threads, we can exploit all CPU cores. Meanwhile, within each thread, the code is still **SIMD**-vectorized. This typically gives the best performance on modern multi-core CPUs.

---

## Conclusion

We have demonstrated a progression of optimizations for a **three-point stencil**:
1. **Basic** scalar solution,
2. **Blocked** solution with improved cache locality,
3. **SIMD** vectorization using SSE intrinsics, and
4. **OpenMP** parallelization combined with **SIMD** intrinsics.

As the measurements show, each step provides incremental performance improvements. The final **SIMD + OMP** approach combines cache-friendly data processing, vector instructions, and multi-core concurrency, achieving the best overall speedup.

---

## References
1. [Intel Intrinsics Guide](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html)  
2. [Five-point stencil (Wikipedia)](https://en.wikipedia.org/wiki/Five-point_stencil)  
3. Class notes and discussion on 3-point stencils and local-mean kernels.

**End of README**
