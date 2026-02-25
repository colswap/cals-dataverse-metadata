# CALS Dataverse — Metadata Standards

서울대학교 농업생명과학대학(CALS) 연구 데이터 통합관리 플랫폼 구축을 위한 메타데이터 표준 정의 저장소입니다.

## 프로젝트 개요

국내외 농업·생명과학 데이터 리포지터리의 메타데이터 표준을 조사·통합하여, CALS 연구 데이터에 적합한 메타데이터 표준을 정의하고 PostgreSQL + JSONB 기반으로 저장·관리합니다.

## 디렉토리 구조

```
├── db/
│   ├── migrations/       # SQL DDL (001_init.sql 등)
│   └── seeds/            # 참조 표준 시드 데이터
├── standards/            # 메타데이터 표준 JSON
│   ├── harvard_dataverse.json    # Harvard Dataverse (DDI, Dublin Core)
│   ├── datacite_4_5.json         # DataCite Metadata Schema 4.5
│   ├── dublin_core.json          # DCMI Terms
│   ├── agmes_agris_fao.json      # AgMES / AGRIS AP (FAO)
│   ├── aihub_kr.json             # 한국 AI 허브 메타데이터 표준
│   ├── smartfarm_kr.json         # 스마트팜 다빈치랩 데이터 포맷
│   ├── wageningen_wur.json       # Wageningen DataCite MDSchema
│   └── snu_cals_labs.json        # SNU CALS 연구실별 커스텀 스키마
├── schema/
│   └── cals_metadata_schema.json # CALS 통합 메타데이터 스키마
├── research/
│   ├── pending_fao.md            # FAO 조사 보류 항목
│   └── skipped_papers.md         # Fetch 실패/스킵 목록
└── CLAUDE.md
```

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

각 연구실의 논문 Materials & Methods 섹션을 역설계하여 정의한 연구실별 메타데이터 필드셋입니다.

| lab_id | 연구실 | 교수 | 데이터 유형 |
|--------|--------|------|------------|
| `snu_bse_laba` | LABA (농업 AI) | 김태형 | 이미지·영상·포인트클라우드 |
| `snu_bse_bicpal` | BICPAL (정밀농업) | 김학진 | GPS·센서퓨전·UAV |
| `snu_plant_crop_science` | 작물생명과학 | 이석하 외 | 유전체·표현형·포장 |
| `snu_plant_horticulture` | 식물공장·시설원예 | 전창후 | 생육·광질·수확후 |
| `snu_forest_lidar_carbon` | 산림원격탐사·탄소 | 산림과학부 다수 | LiDAR·에디공분산·나이테 |
| `snu_abc_plant_micro` | 식물미생물·생물방제 | 응용생물화학부 다수 | 16S·LC-MS·병해충 |
| `snu_food_microbiology_safety` | 식품미생물안전성 | 강동현 외 | 균수·메타지놈·파지 |
| `snu_rse_rural_water_ict` | 농업수자원·ICT | 최진용 | 수문·GIS·수질 |
| `snu_are_agricultural_economics` | 농업·자원경제학 | 농경제사회학부 다수 | 설문·패널·시계열 |
| `snu_food_animal_biotech` | 동물생명공학·유전체 | 이창규 외 | SNP칩·RNA-seq |

모든 스키마는 **DataCite 4.5 / Dublin Core / AgMES / AGROVOC** Crosswalk를 포함합니다.

## 데이터베이스

- **Engine**: PostgreSQL (latest stable)
- **핵심 패턴**: `metadata JSONB` 컬럼으로 계층형 메타데이터 저장
- **마이그레이션**: `db/migrations/` 내 번호 순서 SQL 파일

```bash
psql -U postgres -d cals_research -f db/migrations/001_init.sql
```

## 라이선스

본 저장소의 메타데이터 표준 정의는 연구·교육 목적으로 자유롭게 활용할 수 있습니다.
