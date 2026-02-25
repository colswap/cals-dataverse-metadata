# CALS 데이터버스 — 메타데이터 표준

서울대학교 농업생명과학대학(CALS) 연구 데이터 통합관리 플랫폼 구축을 위한 메타데이터 표준 정의 저장소입니다.

## 프로젝트 개요

국내외 농업·생명과학 데이터 리포지터리의 메타데이터 표준을 조사·통합하여, CALS 연구 데이터에 적합한 메타데이터 표준을 정의하고 PostgreSQL + JSONB 기반으로 저장·관리합니다.

## 디렉토리 구조

```
├── db/
│   ├── migrations/       # SQL DDL (001_init.sql 등)
│   └── seeds/            # 참조 표준 시드 데이터
├── standards/            # 조사된 국제 메타데이터 표준 JSON
│   ├── harvard_dataverse.json    # Harvard Dataverse (DDI, Dublin Core)
│   ├── datacite_4_5.json         # DataCite Metadata Schema 4.5
│   ├── dublin_core.json          # DCMI Terms
│   ├── agmes_agris_fao.json      # AgMES / AGRIS AP (FAO)
│   ├── aihub_kr.json             # 한국 AI 허브 메타데이터 표준
│   ├── smartfarm_kr.json         # 스마트팜 다빈치랩 데이터 포맷
│   ├── wageningen_wur.json       # Wageningen DataCite MDSchema
│   └── snu_cals_labs.json        # SNU CALS 연구실별 domain_metadata 명세
├── schema/
│   ├── cals_metadata_schema_v3.json  # ✅ v3.0 (현행) — 44개 필드, MRO 체계
│   └── cals_metadata_schema.json     # v2.0 (레거시) — 333개 필드, 참조용
├── research/
│   ├── Condensed_CALS_Dataverse_Report.md    # 결정권자 압축 보고서
│   ├── CALS_Dataverse_Strategy_Report.md     # 전략 설계 상세 보고서
│   ├── CALS_Schema_Critical_Review_v3.md     # v2→v3 비판적 검토 및 재설계 근거
│   ├── pending_fao.md                        # FAO 조사 보류 항목
│   └── skipped_papers.md                     # Fetch 실패/스킵 목록
└── CLAUDE.md
```

## 스키마 버전 이력

| 버전 | 파일 | 전체 필드 수 | 파일 크기 | DataCite 준수율 | 상태 |
|------|------|:---:|:---:|:---:|------|
| **v3.0** | `schema/cals_metadata_schema_v3.json` | **44개** | 21 KB | **~80%** | ✅ 현행 권장 |
| v2.0 | `schema/cals_metadata_schema.json` | 333개 | 54 KB | ~40% | 레거시 (참조용) |

### v3.0 핵심 변경 사항

- **MRO 분류 도입**: 필드를 Mandatory(7) · Recommended(7) · Optional(3)으로 분류
- **domain_metadata 자유형 확장**: 10개 강제 도메인 블록 → `extension_type` + `fields` 1개 자유형 블록으로 전환
- **신규 연구실 추가 방법 변경**: core 스키마 수정 불필요 → `standards/snu_cals_labs.json` 참조 명세만 추가
- **등록 최소 요건**: 필수(M) 필드 7개만 채워도 등록 완료

### v3.0 MRO 구조

```
CALS Dataset Record
├── Mandatory (7)
│   ├── identifier          # DOI 또는 CALS-Internal
│   ├── title
│   ├── creator             # ORCID 권장
│   ├── publisher
│   ├── publication_year
│   ├── resource_type
│   └── cals_research
│       ├── department      # 학부 (Harvard Collection Level 1)
│       └── research_domain # 연구 도메인
├── Recommended (7)
│   ├── description, subject (AGROVOC URI), rights
│   ├── date_collected, geo_location
│   ├── funding_reference, related_identifier
│   └── cals_research: lab_id, biological_subject
└── Optional (3)
    ├── contributor, language, version
    └── cals_research: experiment_design, domain_metadata
        └── domain_metadata: extension_type + fields (자유형)
```

## 연구 문서

| 문서 | 설명 | 대상 |
|------|------|------|
| [`Condensed_CALS_Dataverse_Report.md`](research/Condensed_CALS_Dataverse_Report.md) | 현행 설계 진단(3대 리스크), v3.0 구조, 4단계 로드맵 압축 요약 | 의사결정권자 |
| [`CALS_Dataverse_Strategy_Report.md`](research/CALS_Dataverse_Strategy_Report.md) | 7개 국제 표준 분석, 10개 연구실 역설계, 통합 설계 전략 전문 | 아키텍트·운영팀 |
| [`CALS_Schema_Critical_Review_v3.md`](research/CALS_Schema_Critical_Review_v3.md) | v2.0 과잉 설계 진단, v3.0 재설계 근거 Q&A | 기술 검토자 |

## 조사된 국제 표준

| 파일 | 출처 | 표준 |
|------|------|------|
| `harvard_dataverse.json` | Harvard IQSS | DDI 2.5, DataCite 4.5, Dublin Core |
| `datacite_4_5.json` | DataCite | Metadata Schema 4.5 |
| `dublin_core.json` | DCMI | DCMI Terms |
| `agmes_agris_fao.json` | FAO | AgMES, AGRIS AP, AGROVOC |
| `aihub_kr.json` | 한국 AI 허브 | 국내 AI 데이터 메타데이터 표준 |
| `smartfarm_kr.json` | 스마트팜 다빈치랩 | 농업 IoT·스마트팜 포맷 |
| `wageningen_wur.json` | Wageningen University | DataCite MDSchema |

## SNU CALS 연구실 커스텀 스키마 (`snu_cals_labs.json`)

각 연구실의 논문 재료 및 방법(Materials & Methods) 섹션을 역설계하여 정의한 연구실별 `domain_metadata.fields` 명세서입니다. v3.0 core 스키마의 `extension_type`과 연동되어 동적 입력 폼 및 DB 인덱스 기준으로 사용됩니다.

| lab_id | 연구실 | 교수 | 데이터 유형 | extension_type |
|--------|--------|------|------------|----------------|
| `snu_bse_laba` | LABA (농업 AI) | 김태형 | 이미지·영상·포인트클라우드 | `imaging_ai` |
| `snu_bse_bicpal` | BICPAL (정밀농업) | 김학진 | GPS·센서퓨전·UAV | `precision_agriculture` |
| `snu_plant_crop_science` | 작물생명과학 | 이석하 외 | 유전체·표현형·포장 | `genomics_omics` |
| `snu_plant_horticulture` | 식물공장·시설원예 | 전창후 | 생육·광질·수확후 | `controlled_environment` |
| `snu_forest_lidar_carbon` | 산림원격탐사·탄소 | 산림과학부 다수 | LiDAR·에디공분산·나이테 | `forest_remote_sensing` |
| `snu_abc_plant_micro` | 식물미생물·생물방제 | 응용생물화학부 다수 | 16S·LC-MS·병해충 | `plant_microbiology` |
| `snu_food_microbiology_safety` | 식품미생물안전성 | 강동현 외 | 균수·메타지놈·파지 | `food_safety_microbiology` |
| `snu_rse_rural_water_ict` | 농업수자원·ICT | 최진용 | 수문·GIS·수질 | `hydrology_gis` |
| `snu_are_agricultural_economics` | 농업·자원경제학 | 농경제사회학부 다수 | 설문·패널·시계열 | `agri_economics` |
| `snu_food_animal_biotech` | 동물생명공학·유전체 | 이창규 외 | SNP칩·RNA-seq | `genomics_omics` |

모든 스키마는 **DataCite 4.5 / Dublin Core / AgMES / AGROVOC** 크로스워크(Crosswalk)를 포함합니다.

## 데이터베이스

- **엔진**: PostgreSQL (최신 안정 버전)
- **핵심 패턴**: `metadata JSONB` 컬럼으로 계층형 메타데이터 저장
- **GIN 인덱스**: `extension_type` 기반 도메인 필터 + TSVECTOR 전문 검색
- **마이그레이션**: `db/migrations/` 내 번호 순서 SQL 파일

```bash
psql -U postgres -d cals_research -f db/migrations/001_init.sql
```

## 라이선스

본 저장소의 메타데이터 표준 정의는 연구·교육 목적으로 자유롭게 활용할 수 있습니다.
