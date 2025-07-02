import joblib
import pandas as pd

class EnhancedEnergyPredictor:
    def __init__(self, speed_model_path, energy_model_path):
        self.speed_model = joblib.load(speed_model_path)
        self.energy_model = joblib.load(energy_model_path)
        self.phys_params = {
            'base_efficiency': 0.95,
            'temp_coeff': -0.002,
            'soc_coeff': 0.005,
            'slope_factor': 0.15
        }
    
    def predict_speed(self, weight):
        X = pd.DataFrame([[weight]], columns=['weight_kg'])
        return self.speed_model.predict(X)[0]
    
    def predict_energy(self, weight, distance_km, slope_percent, battery_temp=25, soc=80):
        speed = self.predict_speed(weight)
        X_energy = pd.DataFrame([[weight, speed]], columns=['weight_kg', 'speed_kmh'])
        base_energy = self.energy_model.predict(X_energy)[0]
        temp_factor = 1 + self.phys_params['temp_coeff'] * (battery_temp - 25)
        soc_factor = 1 - self.phys_params['soc_coeff'] * abs(50 - soc)/100
        adjusted_energy = base_energy * temp_factor * soc_factor
        slope_factor = 1 + self.phys_params['slope_factor'] * abs(slope_percent)
        energy_per_km = adjusted_energy * slope_factor
        return energy_per_km * distance_km

class NavigationSystem:
    def __init__(self, predictor):
        self.predictor = predictor
    
    def analyze_routes(self, routes, user_data, battery_data):
        weight = user_data['weight']
        battery_capacity = battery_data['capacity']
        soc = battery_data.get('soc', 80)
        
        results = []
        for route in routes:
            total_energy = 0
            total_distance = 0  # 총 거리 계산
            
            for segment in route['segments']:
                segment_energy = self.predictor.predict_energy(
                    weight=weight,
                    distance_km=segment['distance_km'],
                    slope_percent=segment['slope_percent'],
                    soc=soc
                )
                total_energy += segment_energy
                total_distance += segment['distance_km']  # 거리 누적
            
            # 평균 속도 계산
            average_speed = self.predictor.predict_speed(weight)
            
            # 소요시간 계산 (시간 → 분 변환)
            total_travel_time_hours = total_distance / average_speed
            total_travel_time_minutes = total_travel_time_hours * 60
            
            # 배터리 지속시간 계산
            available_energy = battery_capacity * (soc / 100)
            if total_travel_time_hours > 0:
                battery_endurance_hours = available_energy / (total_energy / total_travel_time_hours)
            else:
                battery_endurance_hours = 0
            
            results.append({
                'route_id': route['id'],
                'total_energy': total_energy,
                'battery_usage': (total_energy / available_energy) * 100,
                'is_possible': (total_energy / available_energy) * 100 <= 100,
                'total_distance_km': total_distance,
                'total_travel_time_minutes': round(total_travel_time_minutes, 1),
                'battery_endurance_hours': round(battery_endurance_hours, 2)
            })
        return results
