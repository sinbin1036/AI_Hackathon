from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from geopy.distance import geodesic
from typing import List, Optional
from ai_module import EnhancedEnergyPredictor, NavigationSystem
import sqlite3

# --- 모델 정의 ---
class Point(BaseModel):
    lat: float
    lng: float
    elevation: float

class Segment(BaseModel):
    distance_km: float
    slope_percent: float

class RouteRequest(BaseModel):
    route_id: Optional[str] = None
    points: List[Point]
    user_data: dict
    battery_data: dict

class EnergyPredictRequest(BaseModel):
    weight: float
    distance_km: float
    slope_percent: float
    battery_temp: float = 25
    soc: float = 80

class EnergyPredictResponse(BaseModel):
    predicted_energy: float

class RouteResponse(BaseModel):
    route_id: str
    total_energy: float
    battery_usage: float
    is_possible: bool
    total_distance_km: float
    total_travel_time_minutes: float
    battery_endurance_hours: float

class RouteRequestWithUserID(BaseModel):
    user_id: str
    points: List[Point]
    soc: Optional[float] = None

# --- 상수 및 설정 ---
BRAND_BATTERY = {
    "PERMOBIL": 720,
    "SUNRISE MEDICAL": 672,
    "WHILL": 768
}

# --- FastAPI 앱 초기화 ---
app = FastAPI()

speed_model_path = 'models/speed_predictor.pkl'
energy_model_path = 'models/energy_predictor.pkl'
predictor = EnhancedEnergyPredictor(speed_model_path, energy_model_path)
nav_system = NavigationSystem(predictor)

# --- 유틸 함수 ---
def generate_segments(points: List[Point]) -> List[dict]:
    segments = []
    for i in range(len(points) - 1):
        start = points[i]
        end = points[i + 1]
        distance_km = geodesic((start.lat, start.lng), (end.lat, end.lng)).km
        elevation_diff = end.elevation - start.elevation
        horizontal_distance = distance_km * 1000
        slope_percent = (elevation_diff / horizontal_distance) * 100 if horizontal_distance > 0 else 0
        segments.append({
            "distance_km": distance_km,
            "slope_percent": slope_percent
        })
    return segments

# --- API 엔드포인트 ---
@app.post('/api/save-device-info')
async def save_device_info(request: Request):
    data = await request.json()
    user_id = data.get("id", "apple")
    brand_name = data.get("brand_name")
    user_weight = data.get("user_weight")
    battery_soc = data.get("battery_soc")

    if not (brand_name and battery_soc and user_weight):
        raise HTTPException(status_code=400, detail="모든 필드 필요")

    try:
        conn = sqlite3.connect('userData.db')
        cur = conn.cursor()
        cur.execute('''
            CREATE TABLE IF NOT EXISTS user_profile (
                id TEXT PRIMARY KEY,
                brand_name TEXT NOT NULL,
                user_weight REAL NOT NULL,
                battery_soc REAL NOT NULL
            )
        ''')
        cur.execute('''
            INSERT OR REPLACE INTO user_profile (id, brand_name, user_weight, battery_soc)
            VALUES (?, ?, ?, ?)
        ''', (user_id, brand_name, user_weight, battery_soc))
        conn.commit()
        conn.close()
        return {"result": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/predict-energy', response_model=EnergyPredictResponse)
def predict_energy(data: EnergyPredictRequest):
    try:
        predicted = predictor.predict_energy(
            data.weight,
            data.distance_km,
            data.slope_percent,
            data.battery_temp,
            data.soc
        )
        return {"predicted_energy": float(predicted)}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post('/process-route', response_model=List[RouteResponse])
def process_route(route_request: RouteRequest):
    try:
        segments = generate_segments(route_request.points)
        route = {
            "id": route_request.route_id or "default_route",
            "segments": segments
        }
        results = nav_system.analyze_routes(
            routes=[route],
            user_data=route_request.user_data,
            battery_data=route_request.battery_data
        )
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/process-route-db', response_model=RouteResponse)
def process_route_db(request: RouteRequestWithUserID):
    conn = sqlite3.connect("userData.db")
    cur = conn.cursor()
    cur.execute("SELECT brand_name, user_weight, battery_soc FROM user_profile WHERE id=?", (request.user_id,))
    row = cur.fetchone()
    conn.close()

    if not row:
        raise HTTPException(status_code=404, detail="사용자 정보 없음")

    brand_name, user_weight, battery_soc = row
    brand_upper = brand_name.strip().upper()
    if brand_upper not in BRAND_BATTERY:
        raise HTTPException(status_code=400, detail="지원하지 않는 브랜드입니다.")

    soc = request.soc if request.soc is not None else battery_soc
    user_data = {"weight": user_weight}
    battery_data = {"capacity": BRAND_BATTERY[brand_upper], "soc": soc}
    segments = generate_segments(request.points)
    route = {"id": "db_route", "segments": segments}

    results = nav_system.analyze_routes(
        routes=[route],
        user_data=user_data,
        battery_data=battery_data
    )
    return results[0]

@app.get("/health")
def health_check():
    return {"status": "ok", "version": "1.0.0"}
