# 조사 불가 사이트 및 논문 기록

> 최초 작성: 2026-02-25
> 규칙: Fetch 타임아웃(30초 초과) 또는 접근 불가 시 이 파일에 기록 후 다음 작업으로 이동

---

## 조사 중단 목록

| 순번 | URL | 사유 | 대체 처리 |
|------|-----|------|-----------|
| 1 | https://bse.snu.ac.kr/snu__professor/김태형/ | 사용자 fetch 중단 (병목 의심) | WebSearch 스니펫으로 대체 |
| 2 | https://aims.fao.org/standards/agmes/namespace-specification | 응답 지연 (이전 세션) | agmes_agris_fao.json에 부분 반영 |
| 3 | https://www.fao.org/4/ae909e/ae909e02.htm | 응답 지연 (이전 세션) | 스니펫 기반 작성 |
| 4 | https://raw.githubusercontent.com/IQSS/dataverse/master/scripts/api/data/metadatablocks/citation.tsv | GitHub raw 응답 지연 (이전 세션) | 가이드 문서 기반으로 대체 |

---

## 재시도 예정 목록

| URL | 목적 |
|-----|------|
| https://laba.snu.ac.kr | LABA 연구실 공식 홈페이지 (논문 목록 확인) |
| https://aims.fao.org/standards/agmes | AgMES 전체 요소 목록 |
| https://forestry.snu.ac.kr/en | 산림과학부 교수 목록 및 임산공학 연구실 정보 |
| https://plantmicro.snu.ac.kr | 식물미생물학 전공 교수 및 논문 목록 |
| https://larse.snu.ac.kr | 조경학 전공 연구실 및 논문 목록 |

## snu_cals_labs.json 작업 결과 (2026-02-25)

- 총 10개 연구실 스키마 완성
- 7개 학과/부 커버
- 4개 미완 항목 skipped_labs 배열에 기록
- JSON 유효성 검증 통과

---

## 노트

- WebFetch 실패 시 → WebSearch 스니펫 + DOI 기반 초록 검색으로 대체
- 논문 전문이 필요한 경우 → PubMed/Semantic Scholar 초록 검색 활용
