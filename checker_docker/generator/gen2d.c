#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define STATE_DEAD 0
#define STATE_ALIVE 1


void main(int argc, char **argv)
{
    if (argc < 6)
    {
        printf("ERROR: too few arguments => %s HEIGHT WIDTH NUM_STEPS SEED OUT_FILENAME\n", argv[0]);
        return;
    }

    int height = atoi(argv[1]);
    int width = atoi(argv[2]);

    if (height < 2 || width < 2)
    {
        printf("ERROR: HEIGHT and WIDTH can't be smaller than 2!\n");
        return;
    }

    int num_steps = atoi(argv[3]);
    int seed = atoi(argv[4]);
    const char *output_filename = argv[5];

    srand(seed);

    FILE *fout = fopen(output_filename, "w");

    if (fout == NULL)
    {
        printf("ERROR: can't open file %s!\n", output_filename);
        return;
    }

    fprintf(fout, "2 %d %d %d\n", height, width, num_steps);

    for (int h = 0; h < height; h++)
    {
        for (int w = 0; w < width; w++)
        {
            int state = rand() % 100;

            if (state < 45)
                fprintf(fout, "%d ", STATE_ALIVE);
            else
                fprintf(fout, "%d ", STATE_DEAD);
        }
    }

    fclose(fout);
}
