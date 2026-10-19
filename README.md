# BigData Final: chạy Hadoop bằng Docker

Cấu hình này giúp mỗi thành viên chạy cùng một môi trường HDFS với Hadoop 3.5.0. File CSV được giữ trên máy cá nhân, sau đó mount vào container NameNode dưới dạng chỉ đọc. Metadata và các block của HDFS được lưu trong Docker volumes.

## Yêu cầu

- Docker Desktop có Docker Compose v2
- File dữ liệu đặt tại `data/hotel_bookings_synthetic_200MB.csv`
- macOS/Linux; Windows cần WSL hoặc Git Bash để chạy `scripts/run.sh`

## Khởi động HDFS và nạp dữ liệu

Mở Terminal tại thư mục dự án và chạy:

```bash
./scripts/run.sh
```

Lần chạy đầu tiên, Docker tải image Hadoop 3.5.0, khởi tạo NameNode nếu volume còn trống, rồi khởi động HDFS và nạp CSV vào đường dẫn:

```text
/data/hotel_bookings/input/hotel_bookings_synthetic_200MB.csv
```

Nếu file đã có trên HDFS, script sẽ không nạp lại và sẽ đảm bảo replication factor bằng 3. Để kiểm tra file:

```bash
docker compose exec namenode hdfs dfs -ls -h /data/hotel_bookings/input
docker compose exec namenode hdfs dfs -du -h /data/hotel_bookings/input/hotel_bookings_synthetic_200MB.csv
```

Để xem các block và DataNode đang lưu chúng:

```bash
docker compose exec namenode hdfs fsck /data/hotel_bookings/input/hotel_bookings_synthetic_200MB.csv -files -blocks -locations
```

Giao diện NameNode có tại <http://localhost:9870>.

## Dừng hoặc đặt lại HDFS

Dừng các container nhưng giữ lại dữ liệu HDFS:

```bash
docker compose down
```

Xóa container và các Docker volume của HDFS để lần chạy sau bắt đầu với HDFS trống:

```bash
docker compose down --volumes
```

Lệnh thứ hai xóa metadata và các block HDFS lưu trong Docker; nó không xóa CSV trong thư mục `data/` trên máy.

## Dữ liệu và cấu hình cụm

Mỗi thành viên tự đặt bản CSV của mình tại đường dẫn yêu cầu. Git bỏ qua `data/*.csv`, nên file dữ liệu không được thêm vào repository.

Cấu hình chạy ba DataNode với replication factor 3 và block size 128 MiB. File CSV hiện tại có kích thước 199.999.999 byte, nên được chia thành hai block logic: block đầu 128 MiB, block cuối 65.782.271 byte (khoảng 62,7 MiB). HDFS lưu một bản sao của mỗi block trên từng DataNode. Vì vậy, mỗi DataNode chứa hai bản sao block và toàn cụm có sáu bản sao vật lý.

Cả ba DataNode đều là container chạy trên cùng một máy. Cấu hình này giúp các thành viên tái tạo môi trường làm bài; nó không bảo vệ dữ liệu nếu máy đó gặp sự cố.
