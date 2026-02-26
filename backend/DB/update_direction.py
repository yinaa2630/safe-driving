import csv
import psycopg2

# DB 연결
conn = psycopg2.connect(
    host="192.168.0.47",
    port=5432,
    database="safe_driving",
    user="team",
    password="1234"
)
cur = conn.cursor()

# ----------------------------------------------------------------
# 방향 텍스트 → direction_type 변환 함수
# ----------------------------------------------------------------

# 북쪽/서쪽 기점 도시 목록 (이 도시가 기점이면 → DOWN)
NORTH_WEST_CITIES = [
    '서울', '인천', '춘천', '양양', '강릉', '원주', '수원',
    '일산', '판교', '퇴계원', '평택', '제천', '당진', '서천',
    '공주', '서대전', '회덕', '회턱', '논산', '익산', '고창',
    '담양', '광주광역시', '순천', '영암', '달서', '동대구',
    '대구', '산인', '양평', '삼척', '속초', '언양'
]

def get_direction_type(direction_text):
    direction_text = direction_text.strip()

    # 휴게소는 단순
    if direction_text == '상행':
        return 'UP'
    elif direction_text == '하행':
        return 'DOWN'
    elif direction_text == '양방향':
        return 'BOTH'

    # 졸음쉼터: "XX기점 + YY종점" 형태
    if '기점' in direction_text and '종점' in direction_text:
        # 기점 도시 추출 (예: "서울기점 + 부산종점" → "서울")
        start_city = direction_text.split('기점')[0].strip()

        for city in NORTH_WEST_CITIES:
            if start_city.startswith(city):
                return 'DOWN'  # 북쪽/서쪽 출발 → 남쪽/동쪽으로 내려감

        return 'UP'  # 남쪽/동쪽 출발 → 북쪽/서쪽으로 올라감

    return None  # 판단 불가


# ----------------------------------------------------------------
# 졸음쉼터 (rest_area) 업데이트
# ----------------------------------------------------------------
print("=== 졸음쉼터 업데이트 시작 ===")

with open('전국졸음쉼터표준데이터.csv', encoding='cp949') as f:
    reader = csv.DictReader(f)
    success, fail = 0, 0

    for row in reader:
        name = row['졸음쉼터명'].strip()
        direction = row['도로노선방향'].strip()
        direction_type = get_direction_type(direction)

        if direction_type is None:
            print(f"  [경고] 방향 판단 불가: {name} / {direction}")
            fail += 1
            continue

        cur.execute("""
            UPDATE rest_area
            SET direction = %s, direction_type = %s
            WHERE name = %s
        """, (direction, direction_type, name))
        success += 1

print(f"  완료: {success}건 성공, {fail}건 실패")


# ----------------------------------------------------------------
# 휴게소 (service_station) 업데이트
# ----------------------------------------------------------------
print("=== 휴게소 업데이트 시작 ===")

with open('전국휴게소정보표준데이터.csv', encoding='cp949') as f:
    reader = csv.DictReader(f)
    success, fail = 0, 0

    for row in reader:
        name = row['휴게소명'].strip()
        direction = row['도로노선방향'].strip()
        direction_type = get_direction_type(direction)

        if direction_type is None:
            print(f"  [경고] 방향 판단 불가: {name} / {direction}")
            fail += 1
            continue

        cur.execute("""
            UPDATE service_station
            SET direction = %s, direction_type = %s
            WHERE name = %s
        """, (direction, direction_type, name))
        success += 1

print(f"  완료: {success}건 성공, {fail}건 실패")


# ----------------------------------------------------------------
# 커밋 & 종료
# ----------------------------------------------------------------
conn.commit()
cur.close()
conn.close()
print("\n모든 업데이트 완료!")