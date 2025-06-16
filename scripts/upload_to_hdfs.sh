INPUT="/data/sample_data.csv"
OUTPUT="/data/output/cleaned_$(date +%Y%m%d_%H%M%S).csv"

docker exec namenode python /scripts/etl_process.py "$INPUT" "$OUTPUT"