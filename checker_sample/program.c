#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>

char* TEXT;
long long int LEN_TEXT;

char* readInputFile(const char* filename, long long int* len);
int countPalindromes(const char* text, long long int lenText, long long int lenPalindrome, int rank);
int isPalindrome(const char* str, int lenStr, int rank);

int main(int argc, char *argv[])
{
    if(argc < 3) {
        printf("ERROR: too few arguments: => %s INPUT_FILE OUTPUTFILE\n", argv[0]);
        return -1;
    }

    int rank;
    int nProcesses;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &nProcesses);

    int localCounts[nProcesses];

    // Process with rank 0 reads input file
    if(rank == 0) {
        TEXT = readInputFile(argv[1], &LEN_TEXT);
        // printf("The text has %lld characters.\n", LEN_TEXT);
    }

    // If there is more than one process, share the text to all of them
    if(nProcesses > 1) {
        MPI_Bcast(&LEN_TEXT, 1, MPI_INT, 0, MPI_COMM_WORLD);

        if(rank != 0)
            TEXT = (char*)calloc(LEN_TEXT, sizeof(char));

        MPI_Bcast(TEXT, LEN_TEXT, MPI_CHAR, 0, MPI_COMM_WORLD);
    }

    // Every process gets a subinterval between 1 and LEN_TEXT
    long long int start = rank * ceil((double)LEN_TEXT / (double)nProcesses);
    long long int end = fmin((rank + 1) * ceil((double)LEN_TEXT / (double)nProcesses), LEN_TEXT);
    int localCounter = 0;

    for(int lenPalindrom = start; lenPalindrom < end; lenPalindrom++) {
        // printf("[%d] searching for palindromes (%d)\n", rank, lenPalindrom);
        localCounter += countPalindromes(TEXT, LEN_TEXT, lenPalindrom, rank);
    }

    // printf("%d => [%lld - %lld] => found %d palindromes.\n", rank, start, end, localCounter);

    MPI_Gather(&localCounter, 1, MPI_INT, localCounts, 1, MPI_INT, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        // The call to isPalindrome checks if the whole text is a palindrome
        int totalPalindromes = isPalindrome(TEXT, LEN_TEXT, rank);
        // printf("START: %d\n", totalPalindromes);
        for (int i = 0; i < nProcesses; i++) {
            totalPalindromes += localCounts[i];
        }
        printf("The number of palindromes in the text is: %d\n", totalPalindromes);

        // Write the results
        FILE* fout = fopen(argv[2], "w");
        if(fout == NULL) {
            printf("ERROR: can't open file %s.\n", argv[2]);
            return -1;
        }

        fprintf(fout, "%d", totalPalindromes);
        fclose(fout);
    }

    MPI_Finalize();
    return 0;
}

char* readInputFile(const char* filename, long long int* len)
{
    char* result = NULL;

    FILE* fin = fopen(filename, "r");

    if(fin == NULL) {
        printf("ERROR: can't open file %s.\n", filename);
        return NULL;
    }

    fseek(fin, 0, SEEK_END);
    *len = ftell(fin);
    rewind(fin);

    result = (char*)calloc(*len, sizeof(char));
    fread(result, sizeof(char), *len, fin);

    fclose(fin);

    return result;
}

int countPalindromes(const char* text, long long int lenText, long long int lenPalindrome, int rank)
{
    int counter = 0;

    for(int currentTextOffset = 0; currentTextOffset + lenPalindrome <= lenText; currentTextOffset++)
    {
        counter = counter + isPalindrome(text + currentTextOffset, lenPalindrome, rank);
    }

    return counter;
}

int isPalindrome(const char* str, int lenStr, int rank) {
    if(lenStr < 2) {
        return 0;
    }

    int i = 0;
    int j = lenStr - 1;

    while (i < j) {
        if (str[i] != str[j])
            return 0;
        i++;
        j--;
    }
    // printf("[%d] => %d %.*s IS palindrome\n", rank, lenStr, lenStr, str);

    return 1;
}