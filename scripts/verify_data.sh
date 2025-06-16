HDFS_FILE="/data/output/cleaned_data.csv"
LOCAL_COPY="./downloaded_data.csv"

docker exec namenode hdfs dfs -get "$HDFS_FILE" /tmp/
docker cp namenode:/tmp/cleaned_data.csv "$LOCAL_COPY"

# Сравнение контрольных сумм
original_sum=$(md5sum data/sample_data.csv | awk '{print $1}')
processed_sum=$(md5sum "$LOCAL_COPY" | awk '{print $1}')

if [ "$original_sum" == "$processed_sum" ]; then
    echo "Данные не повреждены"
else
    echo "Обнаружены расхождения"
fi