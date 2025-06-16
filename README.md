# **Учебный проект: ETL-процесс с использованием Hadoop HDFS**  
**Отчет по выполнению проекта**  

---

## **1. Обзор проекта**  
Проект реализует **ETL-процесс (Extract, Transform, Load)** с использованием:  
- **Hadoop HDFS** для распределённого хранения  
- **Python (pandas)** для обработки данных  
- **Docker/Docker Compose** для изоляции окружения  
- **Cron** для автоматической загрузки  

**Этапы выполнения:**  
- Развёрнут Hadoop-кластер (NameNode + DataNode)  
- Реализован Python-скрипт для очистки данных  
- Настроена автоматическая выгрузка в HDFS  
- Добавлена проверка целостности данных

---

## **2. Требования**  
- Docker + Docker Compose  
- Python 3.8+  
- Библиотеки: `pandas`, `hdfs`  
- Bash (для cron и скриптов)

---

## **3. Развертывание Hadoop-кластера** 
### **3.1. docker-compose.yml**
```
services:
  namenode:
    build: .
    container_name: namenode
    ports:
      - "9870:9870"
      - "9000:9000"
    environment:
      - CLUSTER_NAME=hadoop-cluster
      - CORE_CONF_fs_defaultFS=hdfs://namenode:9000
    volumes:
      - hadoop_namenode:/hadoop/dfs/name
      - ./scripts:/scripts
    networks:
      - hadoop

  datanode:
    image: bde2020/hadoop-datanode:2.0.0-hadoop3.2.1-java8
    container_name: datanode
    depends_on:
      - namenode
    environment:
      - CLUSTER_NAME=hadoop-cluster
      - NAMENODE_HOST=namenode
      - CORE_CONF_fs_defaultFS=hdfs://namenode:9000
    volumes:
      - hadoop_datanode:/hadoop/dfs/data
    networks:
      - hadoop

volumes:
  hadoop_namenode:
  hadoop_datanode:

networks:
  hadoop:
```
### **3.2. Запуск**
```
docker-compose up -d
docker ps 
```

---

## **4. Настройка HDFS**
```
docker exec namenode hdfs dfs -mkdir -p /data/input /data/output
docker exec namenode hdfs dfs -chmod -R 777 /data
docker exec namenode hdfs dfs -ls /data
```

---

## **5. ETL-процесс: загрузка и обработка данных**
### **5.1. etl_process.py**
```
import pandas as pd
import sys
from hdfs import InsecureClient

def clean_data(input_file):
    """Удаление пустых строк и дубликатов"""
    df = pd.read_csv(input_file)
    df = df.dropna().drop_duplicates()
    return df

def save_to_hdfs(df, hdfs_path):
    """Сохранение в HDFS"""
    client = InsecureClient('http://namenode:9870', user='root')
    with client.write(hdfs_path, encoding='utf-8') as writer:
        df.to_csv(writer, index=False)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python etl_process.py <input_csv> <hdfs_output_path>")
        sys.exit(1)
    
    input_csv = sys.argv[1]
    hdfs_output = sys.argv[2]
    
    cleaned_data = clean_data(input_csv)
    save_to_hdfs(cleaned_data, hdfs_output)
    print("Данные сохранены в HDFS: {}".format(hdfs_output))
```
### **5.2. Запуск**
```
docker cp data/sample_data.csv namenode:/tmp/
docker exec namenode python3 /scripts/etl_process.py /tmp/sample_data.csv /data/output/cleaned.csv
```
---

## **6. Автоматизация загрузки данных**
### **6.1. upload_to_hdfs.sh**
```
INPUT="/tmp/sample_data.csv"
OUTPUT="/data/output/cleaned_$(date +%Y%m%d_%H%M%S).csv"

docker exec namenode python3 /scripts/etl_process.py "$INPUT" "$OUTPUT"
```
### **6.2. Настройка cron**
```
(crontab -l 2>/dev/null; echo "*/5 * * * * /bin/bash /scripts/upload_to_hdfs.sh >> /logs/etl.log 2>&1") | crontab -
crontab -l  # Проверка
```
---

## **7. Работа с HDFS**
| Команда                                  | Описание             |
| ---------------------------------------- | -------------------- |
| `hdfs dfs -ls /data`                     | Просмотр содержимого |
| `hdfs dfs -cat /data/output/cleaned.csv` | Просмотр данных      |
| `hdfs dfs -du -h /data`                  | Проверка объёма      |
| `hdfs dfs -rm /data/output/old.csv`      | Удаление файла       |

---

## **8. Проверка целостности данных**
### **8.1. verify_data.sh**
```
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
```
### **8.2. Запуск**
```
chmod +x scripts/verify_data.sh
./scripts/verify_data.sh
```

---

## **9. Структура проекта**
```
hadoop-etl-project/
├── data/
│   └── sample_data.csv
├── scripts/
│   ├── etl_process.py
│   ├── upload_to_hdfs.sh
│   └── verify_data.sh
├── docker-compose.yml
├── Dockerfile
├── README.md
└── requirements.txt
```
---

## **10. Заключение**
 - Развёрнут и проверен кластер Hadoop
 - Реализован полноценный ETL-скрипт на Python
 - Настроен cron для регулярной загрузки данных
 - Верифицирована целостность данных
