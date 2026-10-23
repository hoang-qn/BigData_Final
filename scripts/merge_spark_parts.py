#!/usr/bin/env python3
"""Gộp các part CSV do Spark tạo thành một file CSV."""

import argparse
import csv
import os
from pathlib import Path


def merge_parts(folder: Path, output: Path, overwrite: bool) -> tuple[int, int]:
    if not folder.is_dir():
        raise ValueError(f"Không tìm thấy thư mục: {folder}")

    part_files = sorted(folder.glob("part-*.csv"))
    if not part_files:
        raise ValueError(f"Không tìm thấy file part-*.csv trong {folder}")
    if output.exists() and not overwrite:
        raise FileExistsError(
            f"File đã tồn tại: {output}. Thêm --overwrite nếu muốn ghi đè."
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(f".{output.name}.tmp")
    if temporary.exists():
        raise FileExistsError(f"File tạm đã tồn tại: {temporary}; hãy kiểm tra hoặc xóa nó.")

    expected_header = None
    rows_written = 0

    try:
        with temporary.open("w", newline="", encoding="utf-8") as output_file:
            writer = csv.writer(output_file)

            for part_file in part_files:
                with part_file.open("r", newline="", encoding="utf-8") as input_file:
                    reader = csv.reader(input_file)
                    header = next(reader, None)
                    if header is None:
                        continue

                    if expected_header is None:
                        expected_header = header
                        writer.writerow(header)
                    elif header != expected_header:
                        raise ValueError(f"Header không khớp trong file {part_file.name}")

                    for row in reader:
                        writer.writerow(row)
                        rows_written += 1

        if expected_header is None:
            raise ValueError("Các file part đều rỗng hoặc không có header.")

        os.replace(temporary, output)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise

    return len(part_files), rows_written


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Gộp các file part-*.csv của Spark, chỉ giữ một dòng header."
    )
    parser.add_argument("folder", type=Path, help="Thư mục chứa các file part-*.csv")
    parser.add_argument(
        "-o", "--output", type=Path,
        help="Đường dẫn CSV đầu ra (mặc định: hotel_bookings_cleaned.csv trong thư mục input)",
    )
    parser.add_argument(
        "--overwrite", action="store_true",
        help="Cho phép ghi đè file đầu ra đã tồn tại",
    )
    args = parser.parse_args()

    output = args.output or args.folder / "hotel_bookings_cleaned.csv"
    try:
        part_count, row_count = merge_parts(args.folder, output, args.overwrite)
    except (FileExistsError, ValueError) as error:
        parser.error(str(error))

    print(f"Đã gộp {part_count} file part, {row_count:,} dòng dữ liệu.")
    print(f"File đầu ra: {output}")


if __name__ == "__main__":
    main()
