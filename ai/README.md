# ai관련 생성파일 및 핵심코드 공유
>> 먼저 Anaconda와 Spyder 설치 (설치할때 물어보시면 파일 보내드릴게요!)

>>필수 개발환경 설정들 (Anaconda prompt에서 해당명령어들 입력)
conda activate aip >> 반드시 해줘야함, pip와 conda가 꼬이는걸 방지해줌
conda install -c pytorch pytorch
pip install tensorflow
pip install keras
pip install xgboost
pip install pybullet
pip install scikit-learn pandas joblib
{import sklearn
import pandas
import joblib
print("모든 패키지가 정상적으로 설치되었습니다!")} >> {} 뺴고 import부터 소괄호까지 입력후 패키지 존재하는지 확인 없으면 다운로드




1. 리튬배터리에 대한 전비관련 ai학습
>> ev_battery_charging_data.csv 파일을 작업중인 폴더안에 넣어줌 (이 파일은 첨부가 힘들어서 원할때 말씀해주시면 보내드릴게요!)
   ![image](https://github.com/user-attachments/assets/aee5fee5-5b02-4410-aeca-9141c237412c)
![image](https://github.com/user-attachments/assets/aee5fee5-5b02-4410-aeca-9141c237412c)
위의 이미지처럼 코드를 입력하면 csv 파일학습완료.

 2. 체중, 이동속도(평균 3.6km/h로 잡음), 이동거리(100m당으로 잡음)당 에너지 소비량 ai학습
 >> 관련 논문을 학습시키기위해 csv파일로 변환 (마찬가지로 관련 논문은 원할때 말씀해주시면 보내드릴게요!)
 ![image](https://github.com/user-attachments/assets/402d4a68-91f1-49d7-ad53-d6b082a5d1f9)
![image](https://github.com/user-attachments/assets/402d4a68-91f1-49d7-ad53-d6b082a5d1f9)
위의 이미지처럼 코드를 입력하면 csv파일 생성완료.

*추출해온 데이터들 (참고용)
![image](https://github.com/user-attachments/assets/b65d75d8-27fc-4de4-96eb-cf87b08f77e8)
![image](https://github.com/user-attachments/assets/b65d75d8-27fc-4de4-96eb-cf87b08f77e8)

*csv파일 학습코드
![image](https://github.com/user-attachments/assets/4c955052-4c1e-4406-9151-28b1eab5826a)
![image](https://github.com/user-attachments/assets/4c955052-4c1e-4406-9151-28b1eab5826a)

*학습은 종료, 학습한걸 토대로 계산을 수행하기전 pkl생성 필수 (pkl생성코드 밑에)
![image](https://github.com/user-attachments/assets/8b4b75e6-df7f-468f-aa1a-2e83559ba81a)
![image](https://github.com/user-attachments/assets/8b4b75e6-df7f-468f-aa1a-2e83559ba81a)

*통합전비코드 (사진 이어서 보시면됩니다!)
![image](https://github.com/user-attachments/assets/ec2679ea-7c56-4c33-ac59-4baef3cd7f6c)
![image](https://github.com/user-attachments/assets/ec2679ea-7c56-4c33-ac59-4baef3cd7f6c)
![image](https://github.com/user-attachments/assets/8d27f381-2300-401f-b563-8328675babd0)
![image](https://github.com/user-attachments/assets/8d27f381-2300-401f-b563-8328675babd0)


