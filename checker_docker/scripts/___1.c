#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#define MAX_THREADS 8 // Maximum number of threads

// Structure to hold the data for each thread
typedef struct {
    double *v1;
    double *v2;
    double *result;
    int start;
    int end;
} ThreadData;

// Function to add two vectors for a portion handled by a thread
void* addVectors(void* arg) {
    ThreadData* data = (ThreadData*)arg;
	for(int j=0;j<100;j++)
	{
    for (int i = data->start; i < data->end; i++) {
        data->result[i] = data->v1[i] + data->v2[i];
    }
	}

    return NULL;
}

// Function to read vectors from a file
void readVectorsFromFile(const char *filename, double **vector1, double **vector2, int *size) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("Error opening file");
        exit(EXIT_FAILURE);
    }

    fscanf(file, "%d", size); // Read the size of the vectors
    *vector1 = (double *)malloc(*size * sizeof(double)); // Allocate memory for the first vector
    *vector2 = (double *)malloc(*size * sizeof(double)); // Allocate memory for the second vector

    // Read first vector
    for (int i = 0; i < *size; i++) {
        fscanf(file, "%lf", &(*vector1)[i]);
    }

    // Read second vector
    for (int i = 0; i < *size; i++) {
        fscanf(file, "%lf", &(*vector2)[i]);
    }

    fclose(file);
}

// Function to write the resultant vector to an output file
void writeVectorToFile(const char *filename, double *vector, int size) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        perror("Error opening output file");
        exit(EXIT_FAILURE);
    }

    fprintf(file, "%d\n", size); // Write the size of the vector
    for (int i = 0; i < size; i++) {
        fprintf(file, "%.2lf\n", vector[i]); // Write each element of the vector
    }

    fclose(file);
}

int main(int argc, char *argv[]) {
    double *vector1, *vector2, *result;
    int size;

    // Check if the number of threads, input filename, and output filename are provided
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <NumThreads> <inFilename> <outFilename>\n", argv[0]);
        return EXIT_FAILURE;
    }

    int numThreads = atoi(argv[1]); // Convert argument to integer

    // Validate number of threads
    if (numThreads < 1 || numThreads > MAX_THREADS) {
        fprintf(stderr, "Number of threads must be between 1 and %d\n", MAX_THREADS);
        return EXIT_FAILURE;
    }

    const char *inputFilename = argv[2]; // Get input filename
    const char *outputFilename = argv[3]; // Get output filename

    printf("%s",inputFilename);
    // Read vectors from the specified file
    readVectorsFromFile(inputFilename, &vector1, &vector2, &size);

    // Allocate memory for the result vector
    result = (double *)malloc(size * sizeof(double));

    pthread_t threads[MAX_THREADS];
    ThreadData threadData[MAX_THREADS];

    int chunkSize = size / numThreads; // Determine the size of each chunk
    for (int i = 0; i < numThreads; i++) {
        threadData[i].v1 = vector1;
        threadData[i].v2 = vector2;
        threadData[i].result = result;
        threadData[i].start = i * chunkSize;
        // Set end for the last thread to the total size
        threadData[i].end = (i == numThreads - 1) ? size : (i + 1) * chunkSize;

        // Create threads
        if (pthread_create(&threads[i], NULL, addVectors, (void*)&threadData[i]) != 0) {
            perror("Error creating thread");
            exit(EXIT_FAILURE);
        }
    }

    // Wait for all threads to complete
    for (int i = 0; i < numThreads; i++) {
        pthread_join(threads[i], NULL);
    }

    // Write the result to the specified output file
    writeVectorToFile(outputFilename, result, size);

    // Print the result to the console
    printf("Resultant vector written to '%s'.\n", outputFilename);

    // Free the allocated memory
    free(vector1);
    free(vector2);
    free(result);

    return EXIT_SUCCESS;
}
