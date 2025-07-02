from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from geopy.distance import geodesic
from typing import List, Optional
from ai_module import EnhancedEnergyPredictor, NavigationSystem

# 데이터 모델 정의
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
    user_data: dict  # {'weight': float}
    battery_data: dict  # {'capacity': float, 'soc': Optional[float]}

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

# FastAPI 앱 초기화
app = FastAPI()

# 모델 경로 설정
speed_model_path = 'models/speed_predictor.pkl'
energy_model_path = 'models/energy_predictor.pkl'

# AI 예측기 초기화
predictor = EnhancedEnergyPredictor(speed_model_path, energy_model_path)
nav_system = NavigationSystem(predictor)

# 기존 단일 세그먼트 예측 엔드포인트
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
        print(e)
        raise HTTPException(status_code=400, detail=str(e))
    
# 새로운 경로 처리 엔드포인트
@app.post('/process-route', response_model=List[RouteResponse])
def process_route(route_request: RouteRequest):
    try:
        # 1. 포인트 리스트를 세그먼트로 변환
        segments = []
        points = route_request.points
        
        for i in range(len(points) - 1):
            start = points[i]
            end = points[i+1]
            
            # 거리 계산 (km)
            distance_km = geodesic(
                (start.lat, start.lng),
                (end.lat, end.lng)
            ).km
            
            # 경사도 계산
            elevation_diff = end.elevation - start.elevation
            horizontal_distance = distance_km * 1000  # km → m 변환
            slope_percent = (elevation_diff / horizontal_distance) * 100 if horizontal_distance > 0 else 0
            
            segments.append({
                "distance_km": distance_km,
                "slope_percent": slope_percent
            })
        
        # 2. AI 모듈 입력 형식 구성
        route = {
            "id": route_request.route_id or "default_route",
            "segments": segments
        }

        # 3. AI 예측 수행
        results = nav_system.analyze_routes(
            routes=[route],
            user_data=route_request.user_data,
            battery_data=route_request.battery_data
        )
        
        return results
    
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail=str(e))

# 서버 상태 확인용 엔드포인트
@app.get("/health")
def health_check():
    return {"status": "ok", "version": "1.0.0"}