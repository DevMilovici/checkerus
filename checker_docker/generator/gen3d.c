#include <stdio.h>
#include <stdlib.h>

#define STATE_DEAD 0
#define STATE_ALIVE 1

int main(int argc, char **argv) {
    if (argc < 7) {
        printf("ERROR: too few arguments => %s HEIGHT WIDTH DEPTH NUM_STEPS SEED OUT_FILENAME\n", argv[0]);
        return 1;
    }

    int height = atoi(argv[1]);
    int width = atoi(argv[2]);
    int depth = atoi(argv[3]);

    if (height < 2 || width < 2 || depth < 2) {
        printf("ERROR: HEIGHT, WIDTH, and DEPTH can't be smaller than 2!\n");
        return 1;
    }

    int num_steps = atoi(argv[4]);
    int seed = atoi(argv[5]);
    const char *output_filename = argv[6];

    srand(seed);

    FILE *fout = fopen(output_filename, "w");
    if (fout == NULL) {
        printf("ERROR: can't open file %s!\n", output_filename);
        return 1;
    }

    // Output the dimensions and number of steps
    fprintf(fout, "3 %d %d %d %d\n",depth, height, width, num_steps);

    // Generate random states for each cell in the 3D grid
    for (int d = 0; d < depth; d++) {
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                int state = rand() % 100;
                if (state < 45)
                    fprintf(fout, "%d ", STATE_ALIVE);
                else
                    fprintf(fout, "%d ", STATE_DEAD);
            }
            fprintf(fout, "\n"); // Newline after each row in a layer
        }
        fprintf(fout, "\n"); // Blank line after each layer
    }

    fclose(fout);
    return 0;
}
