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