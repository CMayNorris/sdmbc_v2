#!/bin/bash
set -euo pipefail

# Set the inclusive vertical level range and levels handled by each array task.
LEVEL_START=2
LEVEL_END=90
LEVELS_PER_TASK=5
PROJECT_DIR="/home/users/grace.redmond/git_sdmbcv2_MO"

for value in "$LEVEL_START" "$LEVEL_END" "$LEVELS_PER_TASK"; do
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "Level bounds and levels per task must be non-negative integers." >&2
        exit 1
    fi
done

if ((LEVEL_END < LEVEL_START || LEVELS_PER_TASK < 1)); then
    echo "LEVEL_END must be at least LEVEL_START and LEVELS_PER_TASK must be positive." >&2
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
worker_script="${script_dir}/bc_3d_levels_batch_request"
if [[ ! -f "${PROJECT_DIR}/config_3d.yaml" || ! -f "${PROJECT_DIR}/src/sdmbc_main_3d.py" ]]; then
    echo "PROJECT_DIR must contain config_3d.yaml and src/sdmbc_main_3d.py: ${PROJECT_DIR}" >&2
    exit 1
fi
log_dir="${PROJECT_DIR}/slurm-out"
mkdir -p "$log_dir"

task_count=0
level=$LEVEL_START
while ((level <= LEVEL_END)); do
    task_count=$((task_count + 1))
    level=$((level + LEVELS_PER_TASK))
done

array_end=$((task_count - 1))
echo "Submitting ${task_count} tasks for levels ${LEVEL_START}-${LEVEL_END}, ${LEVELS_PER_TASK} level(s) per task."
sbatch --array="0-${array_end}" \
    --output="${log_dir}/bc_3d_levels_%A_%a.out" \
    --error="${log_dir}/bc_3d_levels_%A_%a.err" \
    --export="ALL,PROJECT_DIR=${PROJECT_DIR},LEVEL_START=${LEVEL_START},LEVEL_END=${LEVEL_END},LEVELS_PER_TASK=${LEVELS_PER_TASK}" \
    "$worker_script"
