
# Sparse Matrix-Vector Multiplication (SpMV) with COO Format

This repository contains multiple implementations of Sparse Matrix-Vector Multiplication (SpMV) using the Coordinate (COO) format. The COO format uses three arrays (`rows`, `cols`, and `vals`) that store the row indices, the column indices, and the non-zero values of the matrix respectively.

We compare the runtime of five different implementations:
1. **MPI** (from HW2)
2. **OpenMP** (from HW2)
3. **MPI + OpenMP** (from HW2)
4. **CUDA** (new in this assignment)
5. **MPI + CUDA** (new in this assignment)

## 1. Dataset

We used the following matrices from [SuiteSparse](http://sparse.tamu.edu):
- `D6-6`
- `dictionary28`
- `Ga3As3H12`
- `bfly`
- `pkustk14`
- `roadNet-CA`

These matrices are stored in COO format (three arrays: `rows`, `cols`, `vals`) along with a vector `x` for multiplication.  

**Note**: Floating-point inaccuracies may cause slight deviations from the exact sequential result, but the integer parts should match.

## 2. File Organization

```
.
├── README.md                # This file
├── spmv-seq.cpp            # Sequential SpMV in COO format (from HW2)
├── spmv-mpi.cpp            # MPI version (from HW2)
├── spmv-omp.cpp            # OpenMP version (from HW2)
├── spmv-mpi-omp.cpp        # MPI + OpenMP version (from HW2)
├── spmv-cuda.cu            # **CUDA version** (new)
├── spmv-mpi-cuda.cu        # **MPI + CUDA version** (new)
├── perf-cmp.jpg            # Bar chart comparing runtimes among all five versions
└── data/
    ├── D6-6.coo
    ├── dictionary28.coo
    ├── Ga3As3H12.coo
    ├── bfly.coo
    ├── pkustk14.coo
    └── roadNet-CA.coo
```

## 3. Building the Codes

Below are example build commands. Adjust as needed for your system.

### 3.1 Sequential, MPI, OpenMP, MPI+OpenMP

For the older HW2 codes:
```bash
# Sequential
g++ spmv-seq.cpp -o spmv-seq

# MPI
mpicxx spmv-mpi.cpp -o spmv-mpi

# OpenMP
g++ -fopenmp spmv-omp.cpp -o spmv-omp

# MPI + OpenMP
mpicxx -fopenmp spmv-mpi-omp.cpp -o spmv-mpi-omp
```

### 3.2 CUDA

```bash
# CUDA version
nvcc spmv-cuda.cu -o spmv-cuda

# MPI + CUDA version
# Some systems require additional flags; for instance, if you compile with MPI wrappers:
mpicxx -ccbin nvcc spmv-mpi-cuda.cu -o spmv-mpi-cuda
# Alternatively, if you have MPI available via nvcc:
# nvcc spmv-mpi-cuda.cu -lmpi -o spmv-mpi-cuda
```

> **Note**: Depending on your cluster or environment, you may need to load CUDA and/or MPI modules:
>
> ```bash
> module load cuda
> module load openmpi
> ```

## 4. Running the Codes

### 4.1 Command-Line Arguments

All versions follow a similar usage pattern:
```
./executable <matrix_file> <vector_size_file> <num_iterations>
```
- `<matrix_file>`: Path to the `.coo` file containing the sparse matrix in COO format.
- `<vector_size_file>`: The file for the input vector size or the actual input vector.
- `<num_iterations>`: Number of times to run the SpMV (for performance averaging).

Example:
```bash
./spmv-seq data/D6-6.coo data/vector_D6-6 10
```

### 4.2 MPI Execution

For MPI-based codes (with or without CUDA), we typically run:
```bash
mpirun -np <num_processes> ./spmv-mpi data/D6-6.coo data/vector_D6-6 10
```
Likewise for `spmv-mpi-cuda`:
```bash
mpirun -np <num_processes> ./spmv-mpi-cuda data/D6-6.coo data/vector_D6-6 10
```

**Note**: The exact MPI runtime command depends on your environment (e.g., `mpiexec`, `srun`, etc.).

## 5. Explanation of the New Codes

### 5.1 `spmv-cuda.cu`
1. **Data Allocation on GPU**: We allocate device arrays (`d_rows`, `d_cols`, `d_vals`, and `d_x`, `d_y`).
2. **Kernel**: A CUDA kernel is launched with a suitable grid and block configuration. Each thread computes the partial product for one nonzero element, then the result is written (often atomically) to the correct row index in `y`.
   - Alternatively, one can implement a segmented reduction if row entries for a given row are contiguous.
3. **Result Copy Back**: After the kernel finishes, we copy the result vector `d_y` back to host memory and print or compare results.

### 5.2 `spmv-mpi-cuda.cu`
1. **MPI Setup**: We use MPI to distribute the matrix rows among processes. Each process loads a subset of the COO arrays. 
2. **Device Allocation**: On each rank, the local portion of `rows`, `cols`, and `vals` (and the segment of `x` relevant to those columns) is transferred to GPU memory.
3. **CUDA Kernel**: Similar to `spmv-cuda.cu`, but only operates on the local chunk of the matrix.  
4. **MPI Gather/Allgather**: After partial results are computed on GPUs, we gather or reduce them to form the full result vector. The exact communication pattern can vary:
   - Some implementations gather the full `y` vector on the root node.
   - Others do an all-gather if each rank needs the full result.
5. **Result Verification**: Compare partial or final results if needed.

## 6. Performance Comparison

We tested the five implementations on the following matrices: `D6-6`, `dictionary28`, `Ga3As3H12`, `bfly`, `pkustk14`, and `roadNet-CA`. Below is a sample bar chart (`perf-cmp.jpg`) illustrating the total runtime (lower is better). Each bar represents the runtime for one matrix under a particular implementation.

![Performance Comparison](perf-cmp.jpg)

**Observations**:
- The **CUDA** code generally provides a speedup compared to the CPU-only versions (Sequential, OpenMP, MPI, or MPI+OpenMP) for sufficiently large matrices.
- **MPI+CUDA** can further scale performance when multiple GPUs and multiple processes are used (especially for very large matrices).
- For small matrices, the overhead of GPU transfers or MPI communication might outweigh potential speedups.

## 7. Notes and Tips

- **Floating-point Discrepancies**: Minor numeric differences can occur between CPU and GPU results due to floating-point arithmetic order, but the integer parts should match if the outputs are large enough.
- **Tuning**: For larger matrices, you may need to tune block size, grid size, or memory access patterns for the best performance on your GPU(s).
- **MPI Configuration**: You can experiment with different numbers of ranks and block distributions.  
- **System Dependencies**: Adjust build commands as needed for your cluster or local machine.

## 8. References
- [SuiteSparse Matrix Collection](http://sparse.tamu.edu/)  
- [NVIDIA CUDA Toolkit Documentation](https://docs.nvidia.com/cuda/)  
- [MPI Standard](https://www.mpi-forum.org/)  

---
