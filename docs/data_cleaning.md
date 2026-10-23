# Quy tắc làm sạch Hotel Bookings

Notebook mặc định đọc `/data/hotel_bookings/input/hotel_bookings_synthetic_200MB.csv` trên HDFS, áp dụng các quy tắc dưới đây, rồi ghi CSV sạch lên HDFS. Bộ dữ liệu chính có 1.383.291 dòng và 32 cột. Các số liệu trong bảng là kết quả khảo sát dữ liệu thô của bộ 200 MB; số liệu đầu ra và thời gian chạy được tạo lại trong báo cáo JSON sau khi chạy notebook.

| Phát hiện | Số dòng/giá trị ban đầu | Cách xử lý |
| --- | ---: | --- |
| `children` thiếu | 55 | Xóa dòng. Giá trị không chuyển được thành số cũng thành null và bị xóa theo quy tắc này. |
| `country` thiếu | 5.590 | Điền `Unknown`. |
| `agent` thiếu | 188.998 | Điền `Unknown`. |
| `company` thiếu | 1.304.997 | Điền `Unknown`. |
| ADR âm | 15 | Xóa dòng. |
| Dòng trùng hoàn toàn dư | 53.673 | Xóa các dòng dư và giữ một dòng trong mỗi nhóm trùng. |
| Tổng khách bằng 0 | 2.195 | Giữ dòng. |
| Tổng đêm bằng 0 | 8.315 | Giữ dòng. |
| ADR bằng 0 | 22.701 | Giữ dòng. |
| ADR trên 1000 | 8 | Xóa dòng. |

Các số đếm trên là audit dữ liệu thô; một dòng có thể đồng thời vi phạm nhiều điều kiện. Không cộng các số này để suy ra số dòng sẽ bị xóa. Số dòng đầu ra và số lượng thực tế theo từng bước được lấy từ báo cáo mới sau khi chạy notebook.

## Chuẩn hóa dữ liệu

- Khoảng trắng được bỏ ở đầu/cuối ô; các chuỗi thiếu như `nan`, `null` và `n/a` được chuyển thành null.
- Chuỗi số không hợp lệ, NaN/Infinity, số đếm âm hoặc lẻ, giá trị nhị phân ngoài 0/1 và năm/tuần/ngày ngoài miền hợp lệ được chuyển thành null. Không làm tròn số.
- Các giá trị nhận diện được của `hotel`, `reservation_status` và `arrival_date_month` được chuẩn hóa chữ hoa/thường. Giá trị khác được giữ nguyên.
- `country` được viết hoa, ngoại trừ `Unknown`; mã `CN` được đổi thành `CHN`, mã `TMP` được đổi thành `TLS`. Mã `agent` và `company` dạng `9.00` được chuẩn hóa thành `9`; giá trị khác được giữ nguyên.
- `arrival_date` được ghép từ năm, tháng và ngày đến theo định dạng `YYYY-MM-DD`. Ngày không hợp lệ thành null. `reservation_status_date` cũng được chuẩn hóa về định dạng này.
- Các trường hợp `is_canceled` và `reservation_status` không nhất quán, hoặc thứ tự ngày đáng ngờ, được giữ nguyên theo dữ liệu sau chuẩn hóa.

CSV sạch có 32 cột nguồn và cột `arrival_date`. Báo cáo JSON lưu số dòng bị xóa theo từng lý do, số lượng giá trị thiếu được điền, kiểm tra còn lỗi, số null còn lại và thời gian chạy. Các thống kê này không được thêm thành cột vào CSV.

## Thống nhất mã quốc gia

Áp dụng cùng một ánh xạ trong `clean_pandas.ipynb` và `clean_pyspark.ipynb`:

| Mã đầu vào | Mã kết quả | Ý nghĩa |
| --- | --- | --- |
| `CN` | `CHN` | Thống nhất mã Trung Quốc về dạng ba chữ cái. |
| `TMP` | `TLS` | Thay mã East Timor trước đây bằng mã Timor-Leste hiện hành. |

Mã được viết hoa và ánh xạ trước bước xóa dòng trùng trên 32 cột. Vì vậy, hai dòng chỉ khác `CN` và `CHN` sẽ được so sánh sau khi cùng mang mã `CHN`. `Unknown` vẫn biểu thị quốc gia chưa biết; các mã khác được giữ sau khi chuẩn hóa chữ hoa.

Kiểm tra `country_aliases_remaining` trong báo cáo JSON phải bằng 0: CSV kết quả không còn mã `CN` hoặc `TMP`. Trường `rules_version` của hai báo cáo là `hotel-clean-v5`.

Nguồn: [Danh mục mã quốc gia UN](https://unstats.un.org/unsd/methodology/m49/overview/) và [thông báo ISO đổi mã East Timor thành Timor-Leste](https://www.iso.org/files/live/sites/isoorg/files/archive/pdf/en/iso_3166-3_newsletter_i-1.pdf).

## Kiểm tra trước khi ghi

Notebook dừng nếu số dòng không khớp với số dòng đầu vào trừ các dòng bị xóa, hoặc còn children thiếu, ADR âm, ADR trên 1000, số không hợp lệ, category thiếu hay mã quốc gia chưa được ánh xạ. Null còn lại được ghi trong `remaining_missing` để tiện đối chiếu.

## Kết quả và cách chạy

- `notebooks/clean_pandas.ipynb` đọc qua WebHDFS và ghi một CSV vào `/data/hotel_bookings/cleaned/pandas/<run_id>/hotel_bookings.csv`.
- `notebooks/clean_pyspark.ipynb` đọc và ghi HDFS, tạo thư mục `/data/hotel_bookings/cleaned/pyspark/<run_id>/` chứa `part-*.csv`.
- Mỗi lần chạy toàn bộ notebook tạo `run_id` mới; các kết quả HDFS của lần trước vẫn được giữ.
- Báo cáo gần nhất nằm ở `reports/clean_pandas.json` và `reports/clean_pyspark.json` trên máy local.
- CSV tạm Pandas được tạo trong container và tự dọn sau upload. Kết quả HDFS không tự xuất hiện trong thư mục project.

Khởi động môi trường bằng `./scripts/start_notebooks.sh`. Chạy toàn bộ `clean_pandas.ipynb` trước, sau đó chạy toàn bộ `clean_pyspark.ipynb` để tạo kết quả và báo cáo theo cùng quy tắc. Tải kết quả bằng `run_id` mới trong báo cáo rồi gộp các part CSV để đưa vào Power BI. PySpark mặc định kết nối Spark Master tại `spark://spark-master:7077`; thời gian gồm đọc, xử lý, kiểm tra và ghi HDFS.
