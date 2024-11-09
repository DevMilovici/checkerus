#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void generateRandomVectorsFile(const char *filename, int size) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        perror("Error opening file");
        exit(EXIT_FAILURE);
    }

    fprintf(file, "%d\n", size); // Write the size of the vectors

    // Generate first vector
    for (int i = 0; i < size; i++) {
        double randomValue = (double)(rand() % 100) + ((double)rand() / RAND_MAX); // Random value between 0 and 100
        fprintf(file, "%.2lf\n", randomValue); // Write first vector element
    }

    // Generate second vector
    for (int i = 0; i < size; i++) {
        double randomValue = (double)(rand() % 100) + ((double)rand() / RAND_MAX); // Random value between 0 and 100
        fprintf(file, "%.2lf\n", randomValue); // Write second vector element
    }

    fclose(file);
}

int main() {
    srand(time(NULL)); // Seed the random number generator

    int size;
    printf("Enter the size of the vectors: ");
    scanf("%d", &size);

    generateRandomVectorsFile("vectors.txt", size);

    printf("Random vector file 'vectors.txt' generated successfully.\n");

    return 0;
}
