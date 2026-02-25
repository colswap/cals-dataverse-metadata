# CALS 메타데이터 스키마 v2.0 비판적 검토 및 v3.0 재설계 근거

> 작성일: 2026-02-25 | 검토자: 데이터 아키텍트 관점

---

## 진단 요약

| 항목 | v2.0 현황 | 평가 |
|------|-----------|------|
| 전체 필드 수 (재귀) | 333개 | 🔴 DataCite(20개)의 16배 |
| 파일 크기 | 54 KB | 🔴 운영 배포에 과중 |
| domain_extension 필드 수 | 114개 (10개 블록) | 🔴 93%가 단일 블록 전용 |
| 국제 표준(DataCite) 비중 | 약 40% | 🟡 목표 80% 미달 |
| 스키마 강제 구조 vs 자유 확장 | 전부 강제 | 🔴 운영 시 병목 |
| 등록 최소 요건 필드 수 | 7개 (M) | ✅ 적절 |

---

## Q1. "왜 DataCite나 Harvard 표준을 그대로 쓰지 않는가?"

### DataCite만 쓸 때의 치명적 한계

DataCite는 **"이 데이터가 존재한다"** 는 것을 국제적으로 알리는 신분증이다. 그러나 다음 질문에 대답하지 못한다.

```
연구자: "서울대에서 딸기를 다룬 LED 실험 데이터 주세요"

DataCite 검색 결과:
  → subject 필드: "Agricultural Sciences" (전공 분류)
  → description 필드: 자유 텍스트 검색 → "strawberry", "딸기", "Fragaria" 모두 다른 결과
  → 실험 설계, 반복 수, 처리구 정보: 없음
```

**구체적 실패 시나리오**:

1. **이종 언어 검색 실패**: 이석하 교수팀이 `subject: "soybean"`으로 등록하고 전창후 교수팀이 `subject: "콩"`으로 등록하면 같은 재료도 통합 검색 불가. AGROVOC URI(`c_7627`)가 없으면 영구적으로 단절된다.

2. **재현 불가능 데이터**: 김태형 교수팀의 AI 어노테이션 데이터셋을 DataCite만으로 등록하면 annotation_type, dataset_split, class_distribution 정보가 없어, 다른 연구자가 같은 모델을 학습해도 재현이 불가능하다.

3. **농업 실험 검색 불가**: 최진용 교수팀의 SWAT 수문 모형 결과에서 "Yeongsan River, NSE 0.78 이상"을 찾으려면 DataCite로는 전문 텍스트 검색밖에 없다.

### Harvard Dataverse를 그대로 쓸 때의 한계

Harvard의 `biomedical` 메타데이터 블록은 임상시험·조직샘플·질병 코드 중심이다. CALS의 주요 데이터 유형과의 호환성:

| CALS 데이터 유형 | Harvard 표준 블록 | 매핑 가능? |
|----------------|-------------------|-----------|
| LiDAR 포인트 클라우드 | 없음 | ❌ |
| 에디공분산 CO₂ 플럭스 | 없음 | ❌ |
| AI 어노테이션 데이터셋 | 없음 | ❌ |
| GWAS 지노타입 어레이 | `biomedical` 부분 | △ (인간 유전체 중심) |
| 수문 모형 출력 | `geospatial` 부분 | △ |
| 설문 패널 데이터 | `socialscience` | ✅ |

**결론**: DataCite는 '등록·인용'에 필수이므로 반드시 준수한다. 그러나 '농업 연구 데이터의 검색 가능성(Findability)'과 '재현성(Reproducibility)'을 위해서는 최소한의 CALS 전용 확장이 불가결하다. 이 확장의 범위가 v2.0에서는 과도했고, v3.0에서는 압축한다.

---

## Q2. "LABA AI 데이터 같은 특수 형식을 왜 통합 스키마에 끼워넣는가?"

### 분리 vs 통합의 트레이드오프

| 관점 | 통합 메인 스키마 (v2.0 방식) | 분리 참조 스키마 (v3.0 방식) |
|------|----------------------------|------------------------------|
| 검색 통합 | ✅ 단일 쿼리 | ✅ extension_type 인덱스로 동일 |
| 스키마 유지 비용 | 🔴 높음 (10개 블록 동시 유지) | ✅ 낮음 (core만 관리) |
| 신규 연구실 추가 | 🔴 core 스키마 수정 필요 | ✅ snu_cals_labs.json만 추가 |
| 검증 복잡도 | 🔴 조건부 필드 10종 검증 | ✅ core만 엄격 검증 |
| 미입력 필드 오버헤드 | 🔴 114개 중 대부분 빈 칸 | ✅ 필요한 것만 기록 |

### 핵심 인사이트

**"구조는 참조하고, 봉투(envelope)만 표준화하라"**

v3.0의 해법: `domain_metadata` 블록은 `extension_type` (어떤 종류의 도메인인지 식별)과 `fields` (자유 형식 키-값)으로만 구성한다.

```json
{
  "domain_metadata": {
    "extension_type": "imaging_ai",
    "fields": {
      "camera_model": "Basler acA2040-25gc",
      "inter_annotator_agreement": 0.89,
      "dataset_split": {"train": 0.70, "val": 0.15, "test": 0.15}
    }
  }
}
```

- `extension_type`은 인덱싱되어 **"AI 학습 데이터 전체 조회"** 쿼리 지원
- `fields` 내부 구조는 `standards/snu_cals_labs.json`이 **참조 명세서** 역할
- core 스키마는 봉투만 정의하므로 연구실이 늘어나도 수정 불필요

**단과대 차원에서의 판단**: 운영 팀이 10개 블록을 동시에 유지하는 것은 현실적으로 불가능하다. 자유형 `fields` + `snu_cals_labs.json` 참조 방식이 장기 운영에 유리하다.

---

## Q3. "과잉 설계(Over-engineering)는 아닌가?"

### 결론 먼저: YES, 심각한 과잉 설계다

v2.0의 domain_extension 분석:
- 10개 블록, 114개 필드
- 그 중 **106개(93%)는 단 하나의 블록에만 존재**
- 공통 필드는 `sequencing_platform`, `bioinformatics_pipeline`, `cultivation_method`, `analytical_method` 단 4개

이는 10개의 독립 스키마를 하나의 파일에 억지로 결합한 것이다. "메타데이터 표준"이 아니라 "데이터 사전(Data Dictionary)"에 가깝다.

### 즉시 삭제해도 무방한 필드 목록

| 필드 | 삭제 이유 |
|------|-----------|
| `provenance` 블록 (4개 하위 필드) | 데이터 처리 이력은 운영 로그이지 메타데이터가 아님. `description`에 자유 텍스트로 충분. |
| `administrative` 블록 (6개 하위 필드) | status, visibility, reviewed_by 등은 애플리케이션 관심사. DB 별도 컬럼 처리. |
| `measurement_instrument` 블록 (5개 하위 필드) | `domain_metadata.fields`에 도메인별로 넣으면 됨. core에 불필요. |
| `field_location` 블록 (4개 하위 필드) | `geo_location`과 중복. 통합 가능. |
| `retention_policy` 블록 (3개 하위 필드) | 거버넌스 운영 정책이지 데이터셋 메타데이터가 아님. |
| `title.main_en`, `title.subtitle`, `title.alternative` | `title`은 단일 문자열로. 번역·부제는 `related_identifier`나 description으로. |
| `publisher` 전체 객체 → 문자열 | CALS 플랫폼에서는 발행기관이 SNU CALS로 고정. 복잡한 객체 불필요. |
| `lab_group` | `lab_id`와 `department`로 이미 충분. |
| `date` 5종 객체 | `date_collected`(수집 기간)만 Recommended로 유지. 나머지는 DB 타임스탬프로. |
| `format`, `size` | 파일 관리 시스템이 자동 기록. 메타데이터 입력 부담 증가. |
| domain_extension 10개 강제 블록 전체 | → `domain_metadata.extension_type + fields` 자유형으로 대체 |

**제거 결과**: 333 → 약 45개 필드 (86% 감소)

---

## Q4. "Harvard 방식(학부/연구실별 구조)과 호환되는가?"

### Harvard Dataverse의 Collection 계층 구조

```
Harvard Dataverse
├── Root Collection
│   ├── Harvard
│   │   ├── IQSS (Institution)
│   │   │   └── Dataverse (연구 그룹)
│   │   │       └── Dataset (개별 데이터셋)
```

CALS Dataverse를 동일 패턴으로 적용하면:

```
CALS Dataverse (Root)
├── 바이오시스템·소재학부
│   ├── LABA (김태형)          ← department + lab_id로 매핑
│   └── BICPAL (김학진)
├── 식물생산과학부
│   ├── 작물생명과학전공 (이석하)
│   └── 시설원예전공 (전창후)
└── ...
```

### v3.0의 호환성 평가

| Harvard 요구사항 | v3.0 지원 방법 | 결과 |
|-----------------|---------------|------|
| Collection 단위 필터링 | `cals_research.department` enum | ✅ |
| 하위 저장소 단위 필터링 | `cals_research.lab_id` | ✅ |
| 연구실 자율 확장 | `domain_metadata.fields` 자유형 | ✅ |
| 통합 검색 | 상위 필드 (subject, biological_subject) 공유 | ✅ |
| 국제 인덱싱 (DataCite) | M 필드 7개 DataCite 완전 준수 | ✅ |

**결론**: `department` (학부)와 `lab_id` (연구실)가 Collection 계층의 2단계를 자연스럽게 형성한다. core 스키마가 이 두 필드를 보장하므로 어떤 Harvard-style 계층 구조도 수용 가능하다.

---

## v2.0 vs v3.0 비교

| 항목 | v2.0 | v3.0 | 변화 |
|------|------|------|------|
| 전체 필드 수 | 333개 | ~45개 | -86% |
| 파일 크기 | 54 KB | ~8 KB | -85% |
| domain_extension | 10개 강제 블록 (114필드) | 1개 자유형 블록 (extension_type + fields) | 구조 전환 |
| biological_subject | 4개 분리 배열 | 1개 통합 배열 | 단순화 |
| 제거된 블록 | — | provenance, administrative, measurement_instrument, field_location, retention_policy | 5개 블록 |
| DataCite 준수율 | ~40% | ~80% | +40%p |
| 신규 연구실 추가 방법 | core 스키마 수정 | snu_cals_labs.json만 수정 | 분리 |
| 필수 입력 필드 수 | 7개 (M) | 7개 (M) | 유지 |
| 권장 입력 필드 수 | 8개 (R) | 7개 (R) | 유지 |

### v3.0이 현실적인 이유

1. **등록 장벽 감소**: 연구자가 M 필드 7개만 채워도 시스템에 올릴 수 있다. v2.0의 복잡성은 연구자 이탈을 유발한다.
2. **유지보수 가능**: 10개 블록 업데이트 대신 1개 자유형 + 참조 명세서 업데이트만 필요하다.
3. **국제 연동 용이**: DataCite M 필드 6개를 그대로 채우면 즉시 국제 인덱싱 가능하다.
4. **확장 개방성**: `fields`가 자유형이므로 미래의 새로운 연구실·데이터 유형에 코드 변경 없이 대응한다.

---

> 본 검토 결과를 반영하여 `schema/cals_metadata_schema_v3.json`을 작성하였습니다.
