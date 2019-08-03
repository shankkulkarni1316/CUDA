// sorting
#include <stdio.h>
#include <cuda.h>
#include <stdlib.h>

__global__ void gpu_matrixmult (int *gpu_a, int *gpu_c, int N) {

	int j, x;
	
	int tid = blockIdx.x * blockDim.x + threadIdx.x;

	if (tid < N) {
	x = 0;
	for (j = 0; j < N; j++) {  /* count number less than it */
		if (gpu_a[tid] > gpu_a[j]) x++;
				
	}
	gpu_c[x] = gpu_a[tid];
	}

}


void cpu_matrixmult(int *cpu_a, int *cpu_d, int N) {
	int i, j, k;
	int x;
	

	for (k = 0; k < N; k++) {      /* for each number */
		x = 0;
		for (j = 0; j < N; j++) {     /* count number less than it */
			if (cpu_a[k] > cpu_a[j] ) x++;
			
		}
		cpu_d[x] = cpu_a[k];	 /* copy number into correct place */
		
	}
	


}



int main(int argc, char *argv[]) {
	int i, j; 							// loop counters

	
	int N, B, T;  						// size of array in each dimension
	int *a,*c,*d;
	int *dev_a, *dev_c;
	
	int size;							// number of bytes in arrays
	cudaEvent_t start, stop;     				// using cuda events to measure time
	float elapsed_time_ms1, elapsed_time_ms2;       	// which is applicable for asynchronous code also
	float speedup;
	cudaEventCreate(&start);		
	cudaEventCreate(&stop);
	
	

	
	

	
	printf("Enter number of threads in a block:\n");
	scanf("%d", &T);
	if (T > 1024) {  // check for maximum value of T
		printf("Maximum number of threads per block can be 1024. Hence T will be set to its maximum that is: 1024\n");
		T = 1024;
	}
	
	printf("Enter number of blocks in a grid:\n");
	scanf("%d", &B);
	if (B > 65535) {  // check for maximum value of B
		printf("Maximum number of blocks in a grid can be 65535. Hence B will be set to its maximum that is: 65535\n");
		B = 65535;
	}	
	
	printf("Enter number of random numbers N:\n");
	scanf("%d", &N);	// keyboard input



	size = N * sizeof(int);				// number of bytes in total in arrays

	a = (int*) malloc(size);					//dynamically allocated memory for arrays on host
	
	c = (int*) malloc(size);					// results from GPU
	d = (int*) malloc(size);				// results from CPU

	cudaMalloc((void**)&dev_a, size);			// allocate memory on device
	
	cudaMalloc((void**)&dev_c, size);
		
		
	
	
	


		

	srand(3); //initialize random number generator
	for (i=0; i < N; i++) { //load array with numbers
		a[i] = (int)rand();
	}
		
	/*	
		printf("Vector A is:\n");
		for(i=0; i < N; i++) {
			printf("\t%d", a[i]);
		}
		printf("\n");
	*/
	
		
	/* ------------- COMPUTATION DONE ON GPU ----------------------------*/



		cudaMemcpy(dev_a, a , size ,cudaMemcpyHostToDevice);
		

		cudaEventRecord(start, 0); 			// here start time, after memcpy

		gpu_matrixmult<<<1,T*B>>>(dev_a,dev_c,N);
		cudaMemcpy(c, dev_c, size , cudaMemcpyDeviceToHost);

		cudaEventRecord(stop, 0);     			// measure end time
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&elapsed_time_ms1, start, stop );

		printf("Time to calculate results on GPU: %f ms.\n", elapsed_time_ms1); 
	/* ------------- COMPUTATION DONE ON HOST CPU ----------------------------*/

		cudaEventRecord(start, 0);			// use same timing*

		cpu_matrixmult(a,d,N);				// do calculation on host

		cudaEventRecord(stop, 0);     		// measure end time
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&elapsed_time_ms2, start, stop );

		printf("Time to calculate results on CPU: %f ms.\n", elapsed_time_ms2);  // 

		speedup = elapsed_time_ms2/elapsed_time_ms1;
		printf("speed-up is: %f\n", speedup);

		/*
		printf("Vector C is:\n");
		for(i=0; i < N; i++) {
			printf("\t%d", c[i]);
		}
		printf("\n");
		
		printf("Vector D is:\n");
		for(i=0; i < N; i++) {
			printf("\t%d", d[i]);
		}
		printf("\n");	

		*/
	
	
		// checking if both methods give same answer
		int error = 0;
		for (i=0; i < N; i++) {
			
			if (c[i] != d[i]) error = -1;
			
		}
		if (error == -1) printf("ERROR, sequential and parallel versions give different answers\n");
		else printf("Sequential and parallel versions give same answers\n");

		printf("values of T, B and N are: %d\t%d\t%d\n", T, B, N);
	
		
	
	/* --------------  clean up  ---------------------------------------*/
	free(a); free(c);
	cudaFree(dev_a);
	
	cudaFree(dev_c);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	
	
	
	
	return 0;
}