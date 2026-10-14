#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CODE_DIR="${WORKSPACE}/code"
TESTS_DIR="${WORKSPACE}/tests"
MEMORY_SOURCE="${CODE_DIR}/memory_example.c"
MEMORY_PROGRAM="${CODE_DIR}/memory_example"
REGISTRY_SOURCE="${CODE_DIR}/squadron_registry.c"
REGISTRY_PROGRAM="${CODE_DIR}/squadron_registry"
TEMP_DIR="$(mktemp -d)"
MEMORY_VALIDATION="${TEMP_DIR}/memory_example"
REGISTRY_VALIDATION="${TEMP_DIR}/squadron_registry"
PASSES=0
FAILURES=0

trap 'rm -rf -- "${TEMP_DIR}"' EXIT

pass() {
    printf 'PASS: %s\n' "$1"
    PASSES=$((PASSES + 1))
}

fail() {
    printf 'FAIL: %s\n' "$1"
    FAILURES=$((FAILURES + 1))
}

check() {
    local description="$1"
    shift

    if "$@"; then
        pass "${description}"
    else
        fail "${description}"
    fi
}

is_debug_binary() {
    local path="$1"
    local description=""

    [[ -f "${path}" && -x "${path}" ]] || return 1
    description="$(file -b -- "${path}")"
    [[ "${description}" == ELF*executable* && "${description}" == *"with debug_info"* ]]
}

sources_compile_cleanly() {
    gcc -Wall -Wextra -Werror -std=c11 -g -O0 \
        "${MEMORY_SOURCE}" -o "${MEMORY_VALIDATION}" >/dev/null 2>&1 || return 1
    gcc -Wall -Wextra -Werror -std=c11 -g -O0 \
        "${REGISTRY_SOURCE}" -o "${REGISTRY_VALIDATION}" >/dev/null 2>&1
}

valgrind_report_is_clean() {
    local valgrind_file="$1"

    grep -Fq 'All heap blocks were freed -- no leaks are possible' \
        "${valgrind_file}" || return 1
    grep -Fq 'ERROR SUMMARY: 0 errors' "${valgrind_file}"
}

memory_example_is_clean() {
    local output_file="${TEMP_DIR}/memory.out"
    local valgrind_file="${TEMP_DIR}/memory.vg"

    [[ -x "${MEMORY_VALIDATION}" ]] || return 1
    valgrind --tool=memcheck --leak-check=full \
        --show-leak-kinds=all --track-origins=yes \
        "${MEMORY_VALIDATION}" 5 > "${output_file}" \
        2> "${valgrind_file}" || return 1
    grep -qx 'Alertas detectadas: 2' "${output_file}" || return 1
    valgrind_report_is_clean "${valgrind_file}"
}

all_test_cases_exist() {
    local number=0
    local test_name=""

    for ((number = 1; number <= 4; number++)); do
        printf -v test_name 'test%03d' "${number}"
        [[ -f "${TESTS_DIR}/${test_name}.in" ]] || return 1
        [[ -f "${TESTS_DIR}/${test_name}.expected" ]] || return 1
    done
}

functional_suite_passes() {
    [[ -x "${REGISTRY_VALIDATION}" ]] || return 1
    [[ -x "${SCRIPT_DIR}/tests-run.sh" ]] || return 1
    "${SCRIPT_DIR}/tests-run.sh" "${REGISTRY_VALIDATION}" \
        "${TESTS_DIR}" >/dev/null 2>&1
}

valgrind_suite_passes() {
    local input_file=""
    local test_path=""
    local expected_file=""
    local output_file="${TEMP_DIR}/registry.out"
    local valgrind_file="${TEMP_DIR}/registry.vg"

    command -v valgrind >/dev/null 2>&1 || return 1
    [[ -x "${REGISTRY_VALIDATION}" ]] || return 1

    for input_file in "${TESTS_DIR}"/test*.in; do
        test_path="${input_file%.in}"
        expected_file="${test_path}.expected"

        valgrind --tool=memcheck --leak-check=full \
            --show-leak-kinds=all --track-origins=yes \
            "${REGISTRY_VALIDATION}" < "${input_file}" \
            > "${output_file}" 2> "${valgrind_file}" || return 1
        valgrind_report_is_clean "${valgrind_file}" || return 1
        cmp -s "${expected_file}" "${output_file}" || return 1
    done
}

printf '%s\n' '========================================='
printf '%s\n' '==   Verificación de laboratorio VAL   =='
printf '%s\n' '========================================='
printf '\n== Actividades ==========================\n\n'

check "[1.2] Ambos programas compilan sin warnings" sources_compile_cleanly
check "[1.2] memory_example contiene información de depuración" is_debug_binary "${MEMORY_PROGRAM}"
check "[1.2] squadron_registry contiene información de depuración" is_debug_binary "${REGISTRY_PROGRAM}"
check "[2.3] memory_example utiliza solamente valores inicializados" memory_example_is_clean
check "[3.2] tests-run.sh tiene permiso de ejecución" test -x "${SCRIPT_DIR}/tests-run.sh"
check "[3.2] Existen los cuatro pares de archivos de prueba" all_test_cases_exist
check "[3.2] La suite funcional produce los resultados esperados" functional_suite_passes
check "[3.4] valgrind-run.sh tiene permiso de ejecución" test -x "${SCRIPT_DIR}/valgrind-run.sh"
check "[3.5] Los cuatro test cases no presentan problemas de memoria" valgrind_suite_passes
check "[4] check.sh tiene permiso de ejecución" test -x "${SCRIPT_DIR}/check.sh"

printf '\n== Resumen ===============================\n\n'
TOTAL=$((PASSES + FAILURES))
COUNT_WIDTH=${#TOTAL}
printf '%-26s %*d\n' 'Comprobaciones exitosas:' "${COUNT_WIDTH}" "${PASSES}"
printf '%-26s %*d\n\n' 'Comprobaciones pendientes:' "${COUNT_WIDTH}" "${FAILURES}"

if (( FAILURES == 0 )); then
    exit 0
fi

exit 1
