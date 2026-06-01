## 2026-06-01 — Task 2: computeSteering PD + EMA 구현

### 변경 파일
- `Bot_Java/MyCar.java`: computeSteering 시그니처를 7인수로 교체 (prevCenterError, prevSteering 추가). D항(K4*dCenter)과 EMA(alpha*raw + (1-alpha)*prevSteering) 적용. control_driving 호출부 임시 0f, 0f 전달.
- `Bot_Java/TestRunner.java`: testSteering 전체 교체 — EMA smoothing, D항 보정, 오버슈팅 억제 케이스 포함.

### 테스트 결과
전체 PASS (FAIL 없음). 커밋 SHA: 7e84c68
