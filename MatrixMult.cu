
#include <stdio.h>
#include <cuda.h>
#include <stdlib.h>
#define N 10

__global__ void gpu_matrixmult(int *gpu_a, int *gpu_b, int *gpu_c, int N) {
	int k, sum = 0;
	int *a, *b, *c;
	int col = threadIdx.x + blockDim.x * blockIdx.x; 
	int row = threadIdx.y + blockDim.y * blockIdx.y;

      if (col < N && row < N) {
			for (k = 0; k < N; k++) 
          		sum += a[row * N + k] * b[k * N + col];
			c[row * N + col] = sum;
	}

}

void cpu_matrixmult(int *cpu_a, int *cpu_b, int *cpu_c, int N) {
	int i, j, k, sum;
	int row, col;

	for (row =0; row < N; row++)   				// row of a
		for (col =0; col < N; col++) {				// column of b
			sum = 0;
			for(k = 0; k < N; k++) 
          			sum += cpu_a[row * N + k] * cpu_b[k * N + col];
			cpu_c[row * N + col] = sum;
		}

}



int main(int argc, char *argv[])  {
	int i, j; 							// loop counters
	int Grid_Dim_x=1, Grid_Dim_y=1;		//Grid structure values
	int Block_Dim_x=1, Block_Dim_y=1;		//Block structure values
	int noThreads_x, noThreads_y;			// number of threads available in device, each dimension
	int noThreads_block;					// number of threads in a block
	//int N;  						// size of array in each dimension
	int *a,*b,*c,*d;
	int *dev_a, *dev_b, *dev_c;
	int row, col;
	int size;							// number of bytes in arrays
	cudaEvent_t start, stop;     				// using cuda events to measure time
	float elapsed_time_ms;       			// which is applicable for asynchronous code also
	cudaEventCreate(&start);		
	cudaEventCreate(&stop);

/* --------------------ENTER INPUT PARAMETERS AND ALLOCATE DATA -----------------------*/
	//printf("Enter size of matrix N:\n");
	//scanf("%d", &N);	// keyboard input
	
	dim3 Grid(Grid_Dim_x, Grid_Dim_x);	//Grid structure
	dim3 Block(Block_Dim_x,Block_Dim_y);	//Block structure, threads/block limited by specific device
	size = N * N * sizeof(int);				// number of bytes in total in arrays

	a = (int*) malloc(size);					//dynamically allocated memory for arrays on host
	b = (int*) malloc(size);
	c = (int*) malloc(size);					// results from GPU
	d = (int*) malloc(size);				// results from CPU
		

	srand(2);
	for(row=0; row < N; row++) { // load arrays with some numbers
		for(col=0; col < N; col++) {
			a[row * N + col] = rand() % 10;
			b[row * N + col] = rand() % 10;
		}
	}
	
	for(row=0; row < N; row++) {
		for(col=0; col < N; col++) {
			printf("\t%d");
		}
		printf("\n");
	}
	
		
/* ------------- COMPUTATION DONE ON GPU ----------------------------*/

	cudaMalloc((void**)&dev_a, size);			// allocate memory on device
	cudaMalloc((void**)&dev_b, size);
	cudaMalloc((void**)&dev_c, size);

	cudaMemcpy(dev_a, a , size ,cudaMemcpyHostToDevice);
	cudaMemcpy(dev_b, b , size ,cudaMemcpyHostToDevice);

	cudaEventRecord(start, 0); 			// here start time, after memcpy

	gpu_matrixmult<<<Grid,Block>>>(dev_a,dev_b,dev_c,N);
	cudaMemcpy(c, dev_c, size , cudaMemcpyDeviceToHost);

	cudaEventRecord(stop, 0);     			// measure end time
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&elapsed_time_ms, start, stop );

	printf("Time to calculate results on GPU: %f ms.\n", elapsed_time_ms); 
/* ------------- COMPUTATION DONE ON HOST CPU ----------------------------*/

	cudaEventRecord(start, 0);			// use same timing*

	cpu_matrixmult(a,b,d,N);				// do calculation on host

	cudaEventRecord(stop, 0);     		// measure end time
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&elapsed_time_ms, start, stop );

	printf("Time to calculate results on CPU: %f ms.\n", elapsed_time_ms);  // 


/* ------------------- check device creates correct results -----------------*/

/* --------------------- repeat program  ----------------------------------------*/
								//  while loop to repeat calc with different parameters
/* --------------  clean up  ---------------------------------------*/
	free(a); free(b); free(c);
	cudaFree(dev_a);
	cudaFree(dev_b);
	cudaFree(dev_c);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	return 0;
}
