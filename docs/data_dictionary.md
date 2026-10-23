# Từ điển dữ liệu Hotel Bookings

Tài liệu này giải thích các cột trong CSV Hotel Bookings của dự án. CSV gốc có 32 cột. CSV sau làm sạch có 33 cột: 32 cột nguồn và cột `arrival_date`.

Theo quy tắc hiện tại, notebook xóa dòng thiếu `children`, dòng có `adr` âm, dòng có `adr` lớn hơn 1000 và các bản sao dư của dòng trùng hoàn toàn (giữ một dòng). Báo cáo JSON lưu số dòng bị xóa theo từng lý do và các kết quả kiểm tra. CSV sạch có 32 cột nguồn và cột `arrival_date`.

Dữ liệu của dự án được sinh tổng hợp dựa trên bộ Hotel Booking Demand. Ý nghĩa các cột nghiệp vụ tham khảo bài mô tả bộ dữ liệu gốc; các mã và tần suất trong bản tổng hợp có thể khác. Bộ gốc mô tả một dòng là một lượt đặt phòng, không có mã định danh booking được công bố.

## 32 cột trong CSV gốc

### Khách sạn và ngày đến

| Cột | Ý nghĩa |
| --- | --- |
| `hotel` | Loại khách sạn: `City Hotel` (khách sạn thành phố) hoặc `Resort Hotel` (khách sạn nghỉ dưỡng). |
| `arrival_date_year` | Năm dự kiến đến. |
| `arrival_date_month` | Tháng dự kiến đến, thường là tên tháng tiếng Anh. |
| `arrival_date_week_number` | Số tuần trong năm của ngày đến theo dữ liệu nguồn. Không nên tự giả định quy ước tuần nếu chưa đối chiếu nguồn. |
| `arrival_date_day_of_month` | Ngày trong tháng dự kiến đến, từ 1 đến 31. |
| `reservation_status_date` | Ngày trạng thái đặt phòng gần nhất được ghi nhận, chẳng hạn ngày hủy hoặc ngày trả phòng. |

### Tình trạng đặt phòng và thời gian lưu trú

| Cột | Ý nghĩa |
| --- | --- |
| `is_canceled` | Biến nhị phân: `1` là lượt đặt phòng bị hủy, `0` là không bị hủy theo trường này. |
| `lead_time` | Số ngày từ lúc lượt đặt phòng được nhập vào hệ thống khách sạn đến ngày dự kiến đến. |
| `stays_in_weekend_nights` | Số đêm cuối tuần (thứ Bảy hoặc Chủ nhật) khách ở hoặc dự định ở. |
| `stays_in_week_nights` | Số đêm trong tuần (thứ Hai đến thứ Sáu) khách ở hoặc dự định ở. |
| `booking_changes` | Số lần thay đổi lượt đặt phòng sau khi được nhập vào hệ thống, ví dụ đổi ngày đến, số khách, số đêm, bữa ăn hoặc loại phòng. |
| `days_in_waiting_list` | Số ngày lượt đặt phòng nằm trong danh sách chờ trước khi được xác nhận. |
| `reservation_status` | Trạng thái cuối cùng: `Canceled` (đã hủy), `Check-Out` (khách đã ở và trả phòng), `No-Show` (khách không đến nhận phòng). |

`is_canceled` và `reservation_status` liên quan nhưng không phải cùng một cột. Nếu hai trường mâu thuẫn, notebook giữ nguyên dữ liệu sau chuẩn hóa; quy tắc làm sạch hiện tại không tự chọn một trường làm đúng.

### Khách và lịch sử đặt phòng

| Cột | Ý nghĩa |
| --- | --- |
| `adults` | Số người lớn trong lượt đặt phòng. |
| `children` | Số trẻ em; theo mô tả bộ gốc có thể gồm cả trẻ em tính phí và không tính phí. |
| `babies` | Số em bé. |
| `is_repeated_guest` | `1` nếu hồ sơ khách được xem là khách quay lại, `0` nếu không. |
| `previous_cancellations` | Số lượt đặt phòng trước đó của khách đã bị hủy. |
| `previous_bookings_not_canceled` | Số lượt đặt phòng trước đó của khách không bị hủy. |
| `customer_type` | Nhóm lượt đặt phòng: `Contract` (có allotment/hợp đồng), `Group` (thuộc nhóm), `Transient` (không thuộc nhóm/hợp đồng), `Transient-Party` (khách lẻ nhưng đi cùng ít nhất một lượt khách lẻ khác). |
| `country` | Mã quốc gia xuất xứ của khách/đặt phòng; dữ liệu nguồn thường dùng mã ba chữ cái, ví dụ `PRT`. Khi làm sạch, `CN` đổi thành `CHN`, `TMP` đổi thành `TLS`; giá trị thiếu được điền `Unknown`. |

### Bữa ăn, kênh đặt và mã liên quan

| Cột | Ý nghĩa |
| --- | --- |
| `meal` | Gói bữa ăn: `BB` = ăn sáng; `HB` = ăn sáng và thêm một bữa (thường là tối); `FB` = ăn sáng, trưa và tối; `SC` hoặc `Undefined` thường biểu thị không có gói ăn được xác định. |
| `market_segment` | Phân khúc thị trường của lượt đặt phòng, ví dụ `Direct`, `Corporate`, `Online TA`, `Offline TA/TO`, `Groups`, `Complementary`, `Aviation` hoặc `Undefined`. `TA` là đại lý du lịch; `TO` là công ty lữ hành. |
| `distribution_channel` | Kênh phân phối lượt đặt phòng, ví dụ `Direct`, `TA/TO`, `Corporate`, `GDS` hoặc `Undefined`. `GDS` là hệ thống phân phối toàn cầu. |
| `agent` | Mã định danh đại lý du lịch đứng tên tạo lượt đặt phòng. Đây là mã, không phải tên đại lý. |
| `company` | Mã định danh công ty/tổ chức tạo hoặc chịu trách nhiệm thanh toán lượt đặt phòng. Đây là mã, không phải tên công ty. |
| `deposit_type` | Loại tiền đặt cọc: `No Deposit` (không đặt cọc), `Non Refund` (đặt cọc bằng hoặc vượt tổng chi phí lưu trú theo quy tắc nguồn), `Refundable` (đặt cọc thấp hơn tổng chi phí lưu trú theo quy tắc nguồn). |

Các mã `agent`, `company`, `reserved_room_type` và `assigned_room_type` không cho biết danh tính hoặc tên thực tế. Trong dữ liệu nguồn, giá trị rỗng của agent/company có thể mang nghĩa không áp dụng; bản dữ liệu tổng hợp có thể xử lý giá trị thiếu khác. Notebook của dự án chuẩn hóa thiếu thành `Unknown`, không tự gán một mã cụ thể.

### Phòng, giá và yêu cầu dịch vụ

| Cột | Ý nghĩa |
| --- | --- |
| `reserved_room_type` | Mã loại phòng khách đã đặt. Mã được dùng thay tên/đặc điểm phòng. |
| `assigned_room_type` | Mã loại phòng khách được xếp thực tế. Có thể khác phòng đã đặt do vận hành khách sạn hoặc yêu cầu của khách. |
| `adr` | Average Daily Rate: theo mô tả nguồn, tổng giao dịch lưu trú chia cho tổng số đêm lưu trú. Đơn vị tiền tệ không được xác định trong các cột của CSV. |
| `required_car_parking_spaces` | Số chỗ đậu xe khách yêu cầu. |
| `total_of_special_requests` | Số yêu cầu đặc biệt của khách, ví dụ giường đôi hoặc phòng tầng cao. |

## Cột được thêm vào CSV sau làm sạch

| Cột | Ý nghĩa |
| --- | --- |
| `arrival_date` | Ngày đến được ghép từ năm, tháng và ngày đến, định dạng `YYYY-MM-DD`. Ngày không hợp lệ được để null và thống kê trong báo cáo JSON. |

## Lưu ý khi phân tích

- CSV không có `booking_id`; notebook chỉ xóa các bản sao dư khi cả 32 cột nguồn giống nhau sau khi trim, chuẩn hóa chuỗi thiếu và thống nhất mã quốc gia. Notebook giữ lại một dòng đại diện.
- `reserved_room_type` và `assigned_room_type` có thể khác nhau hợp lệ.
- `adr = 0`, số khách bằng 0 và số đêm bằng 0 được giữ. Dòng có `adr > 1000` bị xóa.
- Children thiếu không được điền thành 0; dòng đó bị xóa. Bảng sau làm sạch có thể còn null ở các trường khác như `arrival_date` hoặc `reservation_status_date`. Xem `remaining_missing` và các thống kê kiểm tra trong báo cáo JSON để biết số lượng thực tế sau mỗi lần chạy.

## Nguồn tham khảo

- António, N., de Almeida, A. & Nunes, L. (2019), *Hotel booking demand datasets*, Data in Brief 22, 41–49. [Bài báo và mô tả các biến](https://pmc.ncbi.nlm.nih.gov/articles/PMC6297060/), [DOI](https://doi.org/10.1016/j.dib.2018.11.126).
- Quy tắc xử lý và tên cột bổ sung được đối chiếu với [`clean_pandas.ipynb`](../notebooks/clean_pandas.ipynb), [`clean_pyspark.ipynb`](../notebooks/clean_pyspark.ipynb) và [`data_cleaning.md`](data_cleaning.md).
