# FAO 메타데이터 표준 조사 (보류 중)

> 작성일: 2026-02-24
> 사유: aims.fao.org 응답 지연으로 조사 중단. 별도 시도 필요.

---

## 조사 대상

### 1. AgMES Namespace Specification
- **URL**: https://aims.fao.org/standards/agmes/namespace-specification
- **목적**: AgMES 전체 네임스페이스 요소 목록, 정의, 정제(refinement), 인코딩 스키마 확인
- **비고**: `standards/agmes_fao.json` 파일로 저장 예정

### 2. AGRIS Application Profile (AGRIS AP)
- **URL**: https://www.fao.org/4/ae909e/ae909e02.htm (전체 섹션)
- **목적**: 모든 메타데이터 요소, Dublin Core 매핑, 의무 수준(Mandatory/Recommended/Optional), 설명
- **비고**: `standards/agris_ap_fao.json` 파일로 저장 예정

### 3. FAO AGROVOC Thesaurus
- **URL**: https://agrovoc.fao.org/browse/agrovoc/en/
- **목적**: 농업 주제어 통제어휘(controlled vocabulary) 구조 및 주요 상위 개념 확인
- **비고**: `standards/agrovoc_fao.json` 파일로 저장 예정

---

## 현재 확보된 부분 정보 (기존 검색 결과)

| 항목 | 내용 | 출처 |
|------|------|------|
| AgMES 목적 | Dublin Core 확장, 농업 도메인 특화 메타데이터 요소 세트 | https://aims.fao.org/standards/agmes |
| AgMES 상태 | Deprecated (더 이상 업데이트 없음) | https://www.dcc.ac.uk/resources/metadata-standards/agmes-agricultural-metadata-element-set |
| AGRIS AP 목적 | DC, AGLS, AgMES 기반 농업 문헌 메타데이터 교환 표준 | https://www.fao.org/agris/ |
| AGRIS AP 최소 요건 | LODE-BD M2B 권고사항 준수 (title, creator, publisher 등) | https://www.fao.org/4/ae909e/ae909e02.htm |

---

## Harvard Dataverse Citation TSV (보류)

- **URL**: https://raw.githubusercontent.com/IQSS/dataverse/master/scripts/api/data/metadatablocks/citation.tsv
- **사유**: GitHub raw 파일 응답 지연
- **목적**: Citation 메타데이터 블록 전체 필드 목록 (name, title, fieldType, allowedValues)
- **비고**: `standards/harvard_dataverse.json` 보완용 — 현재 파일은 가이드 문서 기반으로 작성됨

---

## 재시도 방법

```bash
# AgMES namespace
curl -s "https://aims.fao.org/standards/agmes/namespace-specification" > research/fao_agmes_raw.html

# AGRIS AP
curl -s "https://www.fao.org/4/ae909e/ae909e02.htm" > research/fao_agris_ap_raw.html
```
