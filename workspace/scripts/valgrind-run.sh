#!/usr/bin/env bash

set -u

PROGRAM="${1:-}"
TESTS_DIR="${2:-}"
TOTAL=0
PASSES=0
FAILURES=0
ERRORS=0

if [[ -z "${PROGRAM}" || -z "${TESTS_DIR}" ]]; then
    printf 'Uso: %s <RUTA_AL_EJECUTABLE> <DIRECTORIO_DE_TESTS>\n' "$0"
    exit 2
fi

if [[ ! -x "${PROGRAM}" ]]; then
    printf 'ERRO:  No se encontró el ejecutable %s\n' "${PROGRAM}"
    exit 2
fi

if [[ ! -d "${TESTS_DIR}" ]]; then
    printf 'ERRO:  No se encontró el directorio %s\n' "${TESTS_DIR}"
    exit 2
fi

if ! command -v valgrind >/dev/null 2>&1; then
    printf 'ERRO:  Valgrind no está disponible\n'
    exit 2
fi

ulimit -c 0

printf '%s\n' '========================================='
printf '%s\n' '==       Test cases con Valgrind       =='
printf '%s\n' '========================================='
printf '\n== Resultados ===========================\n\n'

shopt -s nullglob
INPUT_FILES=("${TESTS_DIR}"/test*.in)
shopt -u nullglob

if (( ${#INPUT_FILES[@]} == 0 )); then
    printf 'ERRO:  No se encontraron test cases\n'
    exit 2
fi

for input_file in "${INPUT_FILES[@]}"; do
    test_path="${input_file%.in}"
    test_name="$(basename -- "${test_path}")"
    expected_file="${test_path}.expected"
    output_file="${test_path}.out"
    valgrind_file="${test_path}.vg"
    diff_file="${test_path}.diff"

    TOTAL=$((TOTAL + 1))

    if [[ ! -f "${expected_file}" ]]; then
        printf 'ERRO:  %s no tiene archivo .expected\n' "${test_name}"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    rm -f -- "${diff_file}"
    valgrind \
        --tool=memcheck \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        "${PROGRAM}" < "${input_file}" \
        > "${output_file}" 2> "${valgrind_file}"
    program_status=$?

    if (( program_status != 0 )); then
        printf 'ERRO:  %s terminó con código %d\n' "${test_name}" "${program_status}"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    if ! grep -Fq 'All heap blocks were freed -- no leaks are possible' "${valgrind_file}" || \
       ! grep -Fq 'ERROR SUMMARY: 0 errors' "${valgrind_file}"; then
        printf 'FAIL:  %s presenta problemas de memoria\n' "${test_name}"
        FAILURES=$((FAILURES + 1))
        continue
    fi

    if diff -u "${expected_file}" "${output_file}" > "${diff_file}"; then
        printf 'PASS:  %s\n' "${test_name}"
        rm -f -- "${diff_file}" "${valgrind_file}"
        PASSES=$((PASSES + 1))
    else
        printf 'FAIL:  %s produce una salida inesperada\n' "${test_name}"
        FAILURES=$((FAILURES + 1))
    fi
done

printf '\n== Resumen ===============================\n\n'
COUNT_WIDTH=${#TOTAL}
printf '%-20s %*d\n' 'Test cases:' "${COUNT_WIDTH}" "${TOTAL}"
printf '%-20s %*d\n' 'Pruebas exitosas:' "${COUNT_WIDTH}" "${PASSES}"
printf '%-20s %*d\n' 'Pruebas fallidas:' "${COUNT_WIDTH}" "${FAILURES}"
printf '%-20s %*d\n\n' 'Errores:' "${COUNT_WIDTH}" "${ERRORS}"

if (( FAILURES == 0 && ERRORS == 0 )); then
    exit 0
fi

exit 1
