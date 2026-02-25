# CALS 데이터버스 메타데이터 표준 설계

> 발표일: 2026-02-25 | 서울대학교 농업생명과학대학

---

## 1. 국제 표준 조사

### 조사 대상: 7개 표준

```mermaid
flowchart TB
    subgraph SG_A["인용 · 식별"]
        direction TB
        S1["DataCite 4.5<br/>DOI · 인용 필드"]
        S2["Dublin Core<br/>15개 기반 어휘"]
        S3["WUR Yoda<br/>FAIR 원칙 구현"]
    end

    subgraph SG_B["구조 · 계층"]
        direction TB
        S4["Harvard Dataverse<br/>블록 분리 설계"]
    end

    subgraph SG_C["농업 특화"]
        direction TB
        S5["AGRIS AP 2.0 · AgMES<br/>FAO 농업 통제어휘"]
        S6["SmartFarm KR<br/>IoT 센서 포맷"]
    end

    subgraph SG_D["AI 데이터"]
        direction TB
        S7["AI Hub KR<br/>학습 데이터 품질 표준"]
    end

    SG_A --> CALS["CALS v3.0<br/>통합 설계"]
    SG_B --> CALS
    SG_C --> CALS
    SG_D --> CALS
```

### 표준별 기능 커버리지

| 기능 | DataCite | Harvard DV | Dublin Core | AGRIS | AI Hub | SmartFarm | WUR |
|------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| DOI 부여 | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| 농업 통제어휘 | ❌ | △ | ❌ | ✅ | △ | ✅ | △ |
| AI·이미지 지원 | △ | △ | ❌ | ❌ | ✅ | △ | ❌ |
| IoT 센서 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| 국제 상호운용 | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |

> **결론**: 단일 표준으로 CALS 전체 커버 불가 → DataCite 80% 기반 + CALS 최소 확장 불가피

---

## 2. SNU CALS 연구 데이터 현황

### 10개 연구실 분포

```mermaid
flowchart TB
    CALS(["SNU CALS<br/>농업생명과학대학"])

    subgraph D1["바이오시스템·소재학부"]
        direction TB
        L1["LABA 김태형<br/>이미지 · AI · 포인트클라우드"]
        L2["BICPAL 김학진<br/>GPS · UAV · 센서퓨전"]
    end

    subgraph D2["식물생산과학부"]
        direction TB
        L3["작물생명과학 이석하<br/>GWAS · SNP · 포장실험"]
        L4["시설원예 전창후<br/>LED · 생육 · 수확후"]
    end

    subgraph D3["산림과학부 · 응용생물화학부"]
        direction TB
        L5["산림원격탐사<br/>LiDAR · 에디공분산"]
        L6["식물미생물<br/>16S rRNA · LC-MS"]
    end

    subgraph D4["식품동물생명공학 · 농경제 · 수자원"]
        direction TB
        L7["식품미생물 강동현<br/>병원균 불활성화 · 메타지놈"]
        L8["동물생명공학 이창규<br/>RNA-seq · SNP칩"]
        L9["수자원 최진용<br/>SWAT · GIS · 수질"]
        L10["농업경제학<br/>설문 · 패널 · 시계열"]
    end

    CALS --> D1
    CALS --> D2
    CALS --> D3
    CALS --> D4
```

### 데이터 유형 다양성

| 유형군 | 연구실 | 주요 데이터 형식 |
|--------|--------|----------------|
| AI · 센서 | LABA, BICPAL | 이미지·영상, GPS, LiDAR 포인트클라우드 |
| 생명과학 · 유전체 | 작물생명과학, 동물생명공학 | VCF, FASTQ, SNP 어레이 |
| 환경 · 시설 | 시설원예, 산림원격탐사 | 광질 스펙트럼, CO₂ 플럭스, 에디공분산 |
| 미생물 · 식품 | 식물미생물, 식품미생물 | 16S rRNA, LC-MS, 메타지놈 |
| 사회 · 수문 | 농업경제, 수자원 | 설문 패널, SWAT 수문 모형, GIS |

> **과제**: 5개 이질적 데이터 유형군을 단일 표준 체계로 통합 기술

---

## 3. 제안: CALS 메타데이터 스키마 v3.0

### 3-레이어 아키텍처

```mermaid
flowchart TB
    subgraph L1["Layer 1 — Core (DataCite 기반)"]
        direction TB
        C1["identifier · title · creator"]
        C2["publisher · publication_year · resource_type"]
    end

    subgraph L2["Layer 2 — cals_research (CALS 전용)"]
        direction TB
        C3["department · research_domain"]
        C4["lab_id · biological_subject"]
        C5["experiment_design"]
    end

    subgraph L3["Layer 3 — domain_metadata (연구실 자유형)"]
        direction TB
        C6["extension_type — 도메인 식별 키"]
        C7["fields — 자유 JSON"]
    end

    L1 --> L2 --> L3
```

### MRO 필드 체계

```mermaid
flowchart TB
    ROOT(["CALS Dataset Record"])

    subgraph SG_M["Mandatory — 등록 최소 요건 (7개)"]
        direction TB
        M1["identifier · title · creator"]
        M2["publisher · publication_year · resource_type"]
        M3["cals_research.department<br/>cals_research.research_domain"]
    end

    subgraph SG_R["Recommended — 검색·인용 품질 (7개)"]
        direction TB
        R1["description · subject (AGROVOC URI)"]
        R2["rights · date_collected · geo_location"]
        R3["funding_reference · related_identifier"]
        R4["lab_id · biological_subject"]
    end

    subgraph SG_O["Optional — 전문 연구자 (5개)"]
        direction TB
        O1["contributor · language · version"]
        O2["experiment_design"]
        O3["domain_metadata"]
    end

    ROOT --> SG_M
    ROOT --> SG_R
    ROOT --> SG_O
```

### domain_metadata 자유형 확장

```mermaid
flowchart TB
    DM["cals_research.domain_metadata"]

    subgraph SG_TYPE["extension_type — DB 인덱스 · UI 동적 폼 기준"]
        direction LR
        T1["imaging_ai<br/>LABA"]
        T2["precision_agriculture<br/>BICPAL"]
        T3["genomics_omics<br/>작물·동물생명공학"]
        T4["controlled_environment<br/>시설원예"]
        T5["hydrology_gis<br/>수자원"]
        T6["기타 6종"]
    end

    subgraph SG_FIELDS["fields — 자유 JSON (형식 제약 없음)"]
        direction TB
        F1["LABA 예시<br/>camera_model · dataset_split<br/>inter_annotator_agreement"]
        F2["시설원예 예시<br/>ppfd · light_spectrum_peak_nm<br/>nutrient_solution_EC"]
        F3["신규 연구실<br/>core 스키마 변경 없이<br/>fields에 자유 추가"]
    end

    DM --> SG_TYPE
    SG_TYPE --> SG_FIELDS
```

> - `extension_type` → DB GIN 인덱스 + UI 입력 폼 자동 생성 기준
> - `fields` 명세 참조: `standards/snu_cals_labs.json`
> - **신규 연구실 추가 시 core 스키마 수정 불필요**

### FAIR 원칙 구현

| FAIR | 구현 필드 |
|------|---------|
| **F**indable | `identifier` (DOI) · `subject` (AGROVOC URI) · `title` |
| **A**ccessible | `rights` · DataCite 국제 인덱싱 (OpenAIRE, BASE) |
| **I**nteroperable | DataCite 준수율 80% · AGROVOC 다국어 통제어휘 |
| **R**eusable | `experiment_design` · `biological_subject` · `domain_metadata.fields` |

### 핵심 지표

| 항목 | v3.0 |
|------|:---:|
| 전체 필드 수 | **44개** |
| 파일 크기 | **21 KB** |
| DataCite 준수율 | **~80%** |
| 필수 입력 필드 (M) | **7개** |
| 도메인 확장 구조 | **자유형 1블록** |
| 신규 연구실 추가 | **참조 파일만 수정** |

---

> **참조 파일**
> - `schema/cals_metadata_schema_v3.json` — 스키마 정의
> - `standards/snu_cals_labs.json` — 연구실별 domain_metadata.fields 명세
> - GitHub: https://github.com/colswap/cals-dataverse-metadata
