# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

서울대학교 농업생명과학대학(CALS, College of Agriculture and Life Sciences) 연구 데이터 통합관리 플랫폼.

목표: 국내외 농업·생명과학 데이터 리포지터리의 메타데이터 표준을 조사·통합하여, CALS 연구 데이터에 적합한 메타데이터 표준을 정의하고 PostgreSQL + JSONB 기반으로 저장·관리.

## Core Design Principles

- **메타데이터 구조화 최우선**: 모든 데이터 조사 결과는 JSONB 타입에 적합한 계층형(hierarchical) 구조로 정리
- **출처 표기 엄격 적용**: 모든 메타데이터 필드와 스키마 설계는 참조 출처(기관명, URL, 표준명, 버전)를 명시
- **유연한 스키마**: PostgreSQL JSONB를 활용해 연구 분야별 확장 필드를 수용

## Reference Standards & Sources

조사 대상 메타데이터 표준:

| 출처 | 표준/스키마 |
|------|------------|
| Harvard Dataverse | DDI (Data Documentation Initiative), Dublin Core |
| 한국 AI 허브 (aihub.or.kr) | 한국 AI 데이터 메타데이터 표준 |
| 스마트팜 다빈치랩 / 스마트팜 데이터마켓 | 농업 IoT·스마트팜 데이터 포맷 |
| CGIAR / FAO | AGRIS AP, AGROVOC Thesaurus |
| Wageningen Data Competence Center | DataCite MDSchema |
| USDA NAL | AgMES (Agricultural Metadata Element Set) |
| DataCite | DataCite Metadata Schema 4.x |
| Dublin Core | DCMI Terms |

## Database

- **Engine**: PostgreSQL (latest stable)
- **Key pattern**: `metadata JSONB` column for flexible, hierarchical metadata storage
- **Source tracking**: Every record must include a `source` JSONB block:
  ```json
  {
    "source": {
      "institution": "기관명",
      "standard": "표준명 및 버전",
      "url": "https://...",
      "retrieved_at": "YYYY-MM-DD"
    }
  }
  ```
- Schema migrations managed via SQL files in `db/migrations/`

## Project Structure (planned)

```
laba_lab/
├── db/
│   ├── migrations/       # SQL DDL files (numbered, e.g. 001_init.sql)
│   └── seeds/            # Reference metadata standard seed data (with sources)
├── standards/            # Researched metadata standards as structured JSON
│   ├── harvard_dataverse.json
│   ├── aihub_kr.json
│   ├── smartfarm.json
│   ├── datacite.json
│   ├── agmes_usda.json
│   └── ...
├── schema/               # CALS unified metadata schema definition
│   └── cals_metadata_schema.json
└── CLAUDE.md
```

## Commands

```bash
# PostgreSQL (adjust connection string as needed)
psql -U postgres -d cals_research -f db/migrations/001_init.sql

# Validate JSON schema files
npx ajv validate -s schema/cals_metadata_schema.json -d standards/*.json
```

## Metadata Schema Conventions

- 최상위 키: `title`, `creator`, `subject`, `description`, `publisher`, `date`, `type`, `format`, `identifier`, `source`, `language`, `relation`, `coverage`, `rights`
- 농업 확장 키 (AGROVOC/AgMES 기반): `crop`, `experiment_type`, `location`, `sensor_data`, `smart_farm`
- 모든 코드값(controlled vocabulary)은 출처 URI 포함 (`@vocab` 또는 `uri` 서브키)
- 날짜 형식: ISO 8601 (`YYYY-MM-DD` 또는 `YYYY-MM-DDThh:mm:ssZ`)
