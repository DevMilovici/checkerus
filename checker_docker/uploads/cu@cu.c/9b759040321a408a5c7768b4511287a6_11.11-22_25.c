#define _XOPEN_SOURCE 600

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define STATE_DEAD 0
#define STATE_ALIVE 1

char *filenameIN, *filenameOUT;
unsigned char* map;
unsigned char* map1;
int height, width, depth, steps, P;
int dimensions;
pthread_barrier_t barrier;

void read_file(const char* filename)
{
	FILE* f = fopen(filename, "r");
	if (!f) {
		perror("Failed to open file");
		exit(EXIT_FAILURE);
	}
	fscanf(f, "%d", &dimensions);

	if (dimensions == 2) {
		fscanf(f, "%d %d %d", &height, &width, &steps);
		map = malloc(height * width * sizeof(char));
		map1 = malloc(height * width * sizeof(char));

		memset(map1, STATE_DEAD, height * width);

		for (int i = 0; i < height; i++) {
			for (int j = 0; j < width; j++) {
				fscanf(f, "%hhd", &map[i * width + j]);
			}
		}
	}

	if (dimensions == 3) {
		fscanf(f, "%d %d %d %d", &depth, &height, &width, &steps);
		map = malloc(height * width * depth * sizeof(char));
		map1 = malloc(height * width * depth * sizeof(char));

		memset(map1, STATE_DEAD, height * width * depth);

		for (int d = 0; d < depth; d++) {
			for (int i = 0; i < height; i++) {
				for (int j = 0; j < width; j++) {
					fscanf(f, "%hhd", &map[d * height * width + i * width + j]);
				}
			}
		}
	}

	fclose(f);
}

void print_file(const char* filename)
{
	FILE* f = fopen(filename, "w");
	if (!f) {
		perror("Failed to open file");
		exit(EXIT_FAILURE);
	}
	int map_size = 0;
	if (dimensions == 2) {
		fprintf(f, "2 %d %d \n", height, width);
		map_size = width * height;
	} else if (dimensions == 3) {
		fprintf(f, "3 %d %d %d\n", depth, height, width);
		map_size = width * height * depth;
	}

	for (int i = 0; i < map_size; i++) {
		fprintf(f, "%d ", map[i]);
	}
	fclose(f);
}
int count_alive_neighbors2d(int i, int j)
{
	int alive_count = 0;
	int row_above = (i - 1) * width;
	int row_current = i * width;
	int row_below = (i + 1) * width;

	// Precompute valid boundaries
	int has_top = (i > 0);
	int has_bottom = (i < height - 1);
	int has_left = (j > 0);
	int has_right = (j < width - 1);

	// Top-left
	if (has_top && has_left)
		if (map[row_above + (j - 1)] == STATE_ALIVE)
			alive_count += 1;

	// Top
	if (has_top)
		if (map[row_above + j] == STATE_ALIVE)
			alive_count += 1;

	// Top-right
	if (has_top && has_right)
		if (map[row_above + (j + 1)] == STATE_ALIVE)
			alive_count += 1;

	// Left
	if (has_left)
		if (map[row_current + (j - 1)] == STATE_ALIVE)
			alive_count += 1;

	// Right
	if (has_right)
		if (map[row_current + (j + 1)] == STATE_ALIVE)
			alive_count += 1;

	// Bottom-left
	if (has_bottom && has_left)
		if (map[row_below + (j - 1)] == STATE_ALIVE)
			alive_count += 1;

	// Bottom
	if (has_bottom)
		if (map[row_below + j] == STATE_ALIVE)
			alive_count += 1;

	// Bottom-right
	if (has_bottom && has_right)
		if (map[row_below + (j + 1)] == STATE_ALIVE)
			alive_count += 1;

	return alive_count;
}

void* solve_2d_thread(void* args)
{
	int tid = *(int*)args;
	free(args);

	int map_size = width * height;
	int low = tid * map_size / P;
	int high = (tid + 1) * map_size / P;

	for (int s = 0; s < steps; s++) {
		pthread_barrier_wait(&barrier);

		int i = low / width;
		int j = low % width;

		for (int idx = low; idx < high; idx++) {
			if (map[idx] == STATE_ALIVE) {
				// Increment j, and if it overflows, reset and increment i
				if (++j == width) {
					j = 0;
					i++;
				}
				continue;
			}

			int alive_neighbors = count_alive_neighbors2d(i, j);

			if (alive_neighbors == 2)
				map1[idx] = STATE_ALIVE;
			else
				map1[idx] = STATE_DEAD;

			// Increment j, and if it overflows, reset and increment i
			if (++j == width) {
				j = 0;
				i++;
			}
		}

		if (pthread_barrier_wait(&barrier) == PTHREAD_BARRIER_SERIAL_THREAD) {
			unsigned char* tmp = map;
			map = map1;
			map1 = tmp;
			memset(map1, STATE_DEAD, map_size);
		}
	}
	return NULL;
}
int count_alive_neighbors3d(int x, int y, int z)
{
	int alive_count = 0;
	for (int dx = -1; dx <= 1; dx++) {
		for (int dy = -1; dy <= 1; dy++) {
			for (int dz = -1; dz <= 1; dz++) {
				if (dx == 0 && dy == 0 && dz == 0) continue;

				int nx = x + dx;
				int ny = y + dy;
				int nz = z + dz;

				if (nx >= 0 && nx < depth && ny >= 0 && ny < height && nz >= 0 && nz < width) {
					// depth, height, width
					
					int neighbor_index = (nx * height * width) + (ny * width) + nz;
					alive_count += map[neighbor_index] == STATE_ALIVE;
				}
			}
		}
	}
	return alive_count;
}

void* solve_3d_thread(void* args)
{
	int tid = *(int*)args;
	free(args);

	int map_size = width * height * depth;
	int low = tid * map_size / P;
	int high = (tid + 1) * map_size / P;
	memset(map1, STATE_DEAD, map_size);
	for (int s = 0; s < steps; s++) {
		pthread_barrier_wait(&barrier);
		
		for (int idx = low; idx < high; idx++) {
			if (map[idx] == STATE_ALIVE) {
				continue;
			}
			// depth, height, width
			//int neighbor_index = (nx * height * width) + (ny * width) + nz;
			int z = (idx) % width;
			int y = ((idx - z) / width)%height;
			int x = ((idx - z - y * width) / height) / width;

			int alive_neighbors = count_alive_neighbors3d(x, y, z);

			if (alive_neighbors == 2)
				map1[idx] = STATE_ALIVE;
			else
				map1[idx] = STATE_DEAD;
		}

		if (pthread_barrier_wait(&barrier) == PTHREAD_BARRIER_SERIAL_THREAD) {
			unsigned char* tmp = map;
			map = map1;
			map1 = tmp;
			memset(map1, STATE_DEAD, map_size);
		}
	}
	return NULL;
}
void init(char* argv[])
{
	filenameIN = malloc(strlen(argv[1]));
	strcpy(filenameIN, argv[1]);
	filenameOUT = malloc(strlen(argv[2]));
	strcpy(filenameOUT, argv[2]);
	P = atoi(argv[3]);
}
int main(int argc, char* argv[])
{
	if (argc != 4) {
		printf("./%s fileIN fileOUT N_Threads\n", argv[0]);
		exit(0);
	}

	init(argv);
	pthread_t tid[20];
	pthread_barrier_init(&barrier, NULL, P);

	read_file(filenameIN);

	for (int i = 0; i < P; i++) {
		int* tid_ptr = malloc(sizeof(int));
		*tid_ptr = i;
		if (dimensions == 2)
			pthread_create(&tid[i], NULL, solve_2d_thread, tid_ptr);
		else if (dimensions == 3)
			pthread_create(&tid[i], NULL, solve_3d_thread, tid_ptr);
	}

	for (int i = 0; i < P; i++) {
		pthread_join(tid[i], NULL);
	}

	print_file(filenameOUT);

	pthread_barrier_destroy(&barrier);
	free(map);
	free(map1);

	return 0;
}
