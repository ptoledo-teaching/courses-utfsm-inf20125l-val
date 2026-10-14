#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    int threshold;
    int *samples;
    int alerts = 0;

    if (argc != 2)
    {
        fprintf(stderr, "Uso: %s <umbral>\n", argv[0]);
        return 1;
    }

    threshold = atoi(argv[1]);
    samples = malloc(4 * sizeof(int));

    if (samples == NULL)
    {
        fprintf(stderr, "No se pudo reservar memoria\n");
        return 1;
    }

    samples[0] = 1;
    samples[1] = 3;
    samples[3] = 7;

    for (int i = 0; i < 4; i++)
    {
        if (samples[i] < threshold)
        {
            alerts++;
        }
    }

    printf("Alertas detectadas: %d\n", alerts);

    free(samples);
    return 0;
}
