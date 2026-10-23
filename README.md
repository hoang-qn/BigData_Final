# BigData Final

Môi trường chạy Hadoop HDFS và Spark bằng Docker Compose:

- Hadoop 3.5.0: 1 NameNode, 3 DataNode, replication factor 3.
- Python 3.12, Pandas và PySpark 4.1.2.
- Spark Standalone: 1 Master, 3 Worker.

## Chuẩn bị và nạp dữ liệu

Cần Docker Desktop có Docker Compose v2. Trên Windows, chạy bằng WSL hoặc Git Bash.

Đặt file cá nhân tại `data/hotel_bookings_synthetic_200MB.csv`, rồi chạy:

```bash
./scripts/run.sh
```

Script khởi động HDFS và nạp file nếu chưa có. Nếu dữ liệu đã có trên HDFS, không cần bản CSV local. Đường dẫn HDFS:

```text
/data/hotel_bookings/input/hotel_bookings_synthetic_200MB.csv
```

Kiểm tra dữ liệu và các block:

```bash
docker compose exec namenode hdfs dfs -ls -h /data/hotel_bookings/input
docker compose exec namenode hdfs fsck /data/hotel_bookings/input/hotel_bookings_synthetic_200MB.csv -files -blocks -locations
```

Nếu thay nội dung CSV nhưng giữ nguyên tên, script sẽ dùng lại file đã có trên HDFS. Để nạp lại file 200 MB, xóa bản tương ứng trên HDFS rồi chạy lại script:

```bash
docker compose exec namenode hdfs dfs -rm /data/hotel_bookings/input/hotel_bookings_synthetic_200MB.csv
./scripts/run.sh
```

## Chạy notebook

Khởi động JupyterLab, HDFS và Spark phân tán:

```bash
./scripts/start_notebooks.sh
```

Mở <http://localhost:8888> và chạy notebook trên Jupyter server này để dùng đúng kết nối HDFS. Spark mặc định chạy qua ba Worker; kiểm tra chúng tại <http://localhost:8080>. Giao diện NameNode ở <http://localhost:9870>.

- `audit_pandas.ipynb` và `audit_pyspark.ipynb`: kiểm tra dữ liệu, không ghi đè nguồn.
- `clean_pandas.ipynb` và `clean_pyspark.ipynb`: làm sạch dữ liệu. Chạy Pandas trước PySpark để đối chiếu kết quả.
- `train_cancellation_model.ipynb`: huấn luyện và đánh giá theo thời gian mô hình dự đoán hủy từ `data/cleaned/pandas/hotel_bookings.csv`.
  Notebook so sánh Logistic Regression (SGD), Random Forest, XGBoost, LightGBM và Linear SVM; sau khi cập nhật `Dockerfile.audit`, chạy lại `./scripts/start_notebooks.sh` để dựng image có đủ thư viện.
- Quy tắc chi tiết: [docs/data_cleaning.md](docs/data_cleaning.md); ý nghĩa cột: [docs/data_dictionary.md](docs/data_dictionary.md).

Các notebook mặc định đọc file 200 MB. Pandas đọc toàn bộ CSV và tạo bản sao khi làm sạch, nên RAM cần thiết có thể lớn hơn nhiều lần kích thước file. Sau khi đổi dữ liệu, Restart Kernel rồi Run All Pandas trước, PySpark sau để tạo báo cáo và kết quả mới từ cùng đầu vào 200 MB.

PySpark có thể chạy local để so sánh:

```bash
./scripts/start_notebooks.sh local
```

Chạy lại `./scripts/start_notebooks.sh` để quay về chế độ phân tán. Sau khi đổi chế độ, Restart Kernel trong Jupyter.

Kết quả làm sạch được ghi vào HDFS dưới `/data/hotel_bookings/cleaned/<engine>/<run_id>/`. Báo cáo audit và cleaning được tạo trong thư mục `reports/` sau khi chạy notebook; các báo cáo cũ của lần thử đã được dọn. Quy tắc chính: xóa dòng trùng hoàn toàn, dòng thiếu `children`, ADR âm hoặc trên 1000; thiếu `country`, `agent`, `company` được điền `Unknown`. Dòng có 0 khách, 0 đêm hoặc ADR bằng 0 được giữ.

## Tải kết quả về project

Chạy lệnh từ thư mục gốc project khi container `namenode` đang hoạt động. Lấy `run_id` trong trường `output` của báo cáo tương ứng. Nếu đã xóa Docker volumes, hãy chạy lại notebook làm sạch trước vì kết quả trên HDFS đã bị xóa.

### Pandas

```bash
mkdir -p data/cleaned/pandas
docker compose exec -T namenode hdfs dfs -cat /data/hotel_bookings/cleaned/pandas/<run_id>/hotel_bookings.csv > data/cleaned/pandas/hotel_bookings.csv
```

Trong `reports/clean_pandas.json`, `run_id` là đoạn sau `/pandas/` và trước `/hotel_bookings.csv` trong đường dẫn `output`.

### PySpark

```bash
mkdir -p data/cleaned/pyspark
# Dọn thư mục tạm trong container nếu tải lại cùng run_id
docker compose exec -T namenode rm -rf /tmp/clean_pyspark_<run_id>
docker compose exec -T namenode hdfs dfs -get /data/hotel_bookings/cleaned/pyspark/<run_id> /tmp/clean_pyspark_<run_id>
docker compose cp namenode:/tmp/clean_pyspark_<run_id> data/cleaned/pyspark/
```

Trong `reports/clean_pyspark.json`, `run_id` là đoạn cuối sau `/pyspark/` trong đường dẫn `output`. Kết quả gồm một thư mục chứa các file `part-...`. `data/cleaned/` và CSV đầu vào được Git bỏ qua.

Để gộp các file Spark thành một CSV cho Power BI, chạy:

```bash
python scripts/merge_spark_parts.py data/cleaned/pyspark/<run_id>
```

File `hotel_bookings_cleaned.csv` được tạo trong thư mục đó. Nếu file đã tồn tại, thêm `--overwrite` để tạo lại.

## Dừng và dữ liệu lưu trữ

### Tạm dừng không mất dữ liệu

Tắt toàn bộ container nhưng giữ dữ liệu HDFS:

```bash
docker compose --profile audit --profile spark-cluster down
```

Lần tới, mở Docker Desktop rồi chạy lại:

```bash
./scripts/start_notebooks.sh
```

Script khởi động HDFS, JupyterLab và Spark; dữ liệu HDFS vẫn còn trong Docker volumes.

### Xóa container và image, giữ dữ liệu HDFS

Lệnh này xóa container và image của project, nhưng giữ các Docker volumes:

```bash
docker compose --profile audit --profile spark-cluster down --rmi all
```

### Xóa toàn bộ, gồm dữ liệu HDFS

Lệnh này xóa container, image và Docker volumes của project. Dùng lại `./scripts/run.sh` để tạo cụm và nạp lại dữ liệu:

```bash
docker compose --profile audit --profile spark-cluster down --rmi all --volumes
```

Lệnh không xóa CSV local trong `data/`. HDFS lưu metadata và block trong Docker volumes trên máy này; ba DataNode cũng đều chạy trên cùng máy.
