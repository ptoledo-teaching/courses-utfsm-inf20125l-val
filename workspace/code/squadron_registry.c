#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct
{
    char *name;
    int missions;
    int success_rate;
} Unit;

typedef struct
{
    char *summary;
} AuditRecord;

static char *cached_name = NULL;
static char *search_cursor = NULL;

static char *duplicate_text(const char *source)
{
    size_t length = strlen(source);
    char *copy = malloc((length + 1) * sizeof(char));

    if (copy == NULL)
    {
        return NULL;
    }

    strcpy(copy, source);
    return copy;
}

static void destroy_units(Unit *units, int count)
{
    if (units == NULL)
    {
        return;
    }

    for (int i = 0; i < count; i++)
    {
        free(units[i].name);
    }

    free(units);
}

static Unit *read_units(int count)
{
    Unit *units = calloc((size_t)count, sizeof(Unit));
    char buffer[64];

    if (units == NULL)
    {
        return NULL;
    }

    for (int i = 0; i < count; i++)
    {
        if (scanf("%63s %d %d", buffer, &units[i].missions, &units[i].success_rate) != 3)
        {
            destroy_units(units, count);
            return NULL;
        }

        units[i].name = duplicate_text(buffer);
        if (units[i].name == NULL)
        {
            destroy_units(units, count);
            return NULL;
        }
    }

    return units;
}

static double calculate_average_success(const Unit *units, int count)
{
    int total = 0;

    for (int i = 0; i < count; i++)
    {
        total += units[i].success_rate;
    }

    return (double)total / (double)count;
}

static int calculate_total_missions(const Unit *units, int count)
{
    int total = 0;

    for (int i = 0; i < count; i++)
    {
        total += units[i].missions;
    }

    return total;
}

static int find_best_unit(const Unit *units, int count)
{
    int best_index = 0;

    for (int i = 1; i < count; i++)
    {
        if (units[i].success_rate > units[best_index].success_rate)
        {
            best_index = i;
        }
    }

    return best_index;
}

static int audit_name_checksum(const Unit *units, int count)
{
    int checksum = 0;

    for (int i = 0; i < count; i++)
    {
        checksum += (int)strlen(units[i].name);
    }

    return checksum;
}

static void prepare_short_audit(const char *name)
{
    char *audit_name = duplicate_text(name);

    if (audit_name == NULL)
    {
        return;
    }

    if (audit_name[0] == '\0')
    {
        puts("Nombre vacío inesperado");
    }
}

static void prepare_detailed_audit(const char *name)
{
    AuditRecord *record = malloc(sizeof(AuditRecord));

    if (record == NULL)
    {
        return;
    }

    record->summary = duplicate_text(name);
    if (record->summary == NULL)
    {
        free(record);
        return;
    }
}

static void remember_search_position(const char *name)
{
    char *buffer = duplicate_text(name);

    if (buffer == NULL || buffer[0] == '\0')
    {
        free(buffer);
        return;
    }

    search_cursor = buffer + 1;
}

static void cache_best_unit(const char *name)
{
    cached_name = duplicate_text(name);
}

static void prepare_audit(const Unit *units, int count, int best_index)
{
    if (count == 3)
    {
        prepare_short_audit(units[best_index].name);
    }
    else if (count == 4)
    {
        prepare_detailed_audit(units[best_index].name);
    }
    else if (count == 1)
    {
        remember_search_position(units[best_index].name);
    }
    else if (count == 5)
    {
        cache_best_unit(units[best_index].name);
    }
}

int main(void)
{
    int count;
    Unit *units;
    double average_success;
    int total_missions;
    int best_index;
    int checksum;

    if (scanf("%d", &count) != 1 || count <= 0)
    {
        fprintf(stderr, "Error: cantidad de unidades inválida\n");
        return 1;
    }

    units = read_units(count);
    if (units == NULL)
    {
        fprintf(stderr, "Error: no se pudo leer el escuadrón\n");
        return 1;
    }

    average_success = calculate_average_success(units, count);
    total_missions = calculate_total_missions(units, count);
    best_index = find_best_unit(units, count);

    printf("Unidades procesadas : %d\n", count);
    printf("Promedio de éxito   : %.2f\n", average_success);
    printf("Mejor unidad        : %s\n", units[best_index].name);
    printf("Misiones totales    : %d\n", total_missions);

    checksum = audit_name_checksum(units, count);
    if (checksum == -1)
    {
        printf("Checksum inesperado: %d\n", checksum);
    }

    prepare_audit(units, count, best_index);
    destroy_units(units, count);

    return 0;
}
