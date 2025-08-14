#!/usr/bin/env bash
set -e  # 出错就退出

# 路径设置
ALGORITHM_DIR="./baseline-algorithm"
DATASET_DIR="./dataset/trackrad2025_labeled_training_data"
GROUND_TRUTH_PATH="$DATASET_DIR"
OUTPUT_DIR="./local_test_output"
EVAL_DIR="./evaluation"

# 清空旧输出
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "=== Running Algorithm locally without Docker ==="
export case_id="$case_id"
for case_folder in $DATASET_DIR/*; do
    case_id=$(basename "$case_folder")
    echo "[Case] $case_id"

    # 输入路径
    frame_rate="$case_folder/frame-rate.json"
    b_field="$case_folder/b-field-strength.json"
    region="$case_folder/scanned-region.json"
    frames="$case_folder/images/${case_id}_frames.mha"
    first_label="$case_folder/targets/${case_id}_first_label.mha"

    # case 输出路径
    case_out="$OUTPUT_DIR/$case_id"
    mkdir -p "$case_out/images/mri-linac-series-targets"

    # 运行你的推理脚本
    python "$ALGORITHM_DIR/inference.py" \
        --frame_rate "$frame_rate" \
        --b_field "$b_field" \
        --region "$region" \
        --frames "$frames" \
        --first_label "$first_label" \
        --output "$case_out/images/mri-linac-series-targets/output.mha"

    # 生成 prediction.json
    cat > "$case_out/prediction.json" <<EOF
{
  "pk": "$case_id",
  "inputs": [
    { "value": 8, "interface": { "slug": "frame-rate" } },
    { "value": 1.5, "interface": { "slug": "magnetic-field-strength" } },
    { "value": "abdomen", "interface": { "slug": "scanned-region" } },
    {
      "image": { "name": "mri-linac-target.mha" },
      "interface": { "slug": "mri-linac-target", "relative_path": "images/mri-linac-target" }
    },
    {
      "image": { "name": "${case_id}.mha" },
      "interface": { "slug": "mri-linac-series", "relative_path": "images/mri-linacs" }
    }
  ],
  "outputs": [
    {
      "image": { "name": "output.mha" },
      "interface": { "slug": "mri-linac-series-targets", "relative_path": "images/mri-linac-series-targets" }
    }
  ],
  "status": "Succeeded"
}
EOF
done

# 合并 prediction.json
echo "[" > "$OUTPUT_DIR/predictions.json"
find "$OUTPUT_DIR" -name prediction.json -exec sh -c 'cat "{}" && echo ","' \; | sed '$ s/,$//' >> "$OUTPUT_DIR/predictions.json"
echo "]" >> "$OUTPUT_DIR/predictions.json"

echo "=== Running Evaluation locally ==="
python "$EVAL_DIR/evaluate.py" \
    --predictions "$OUTPUT_DIR/predictions.json" \
    --ground_truth "$GROUND_TRUTH_PATH" \
    --output "$OUTPUT_DIR/metrics.json"

echo "=== Done ==="
cat "$OUTPUT_DIR/metrics.json"
