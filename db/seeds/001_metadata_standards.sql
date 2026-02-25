-- =============================================================================
-- Seed: metadata_standards 표준 JSON 전체 내용 연결
-- 001_init.sql의 INSERT 이후 실행
-- schema_json 컬럼에 standards/ 디렉토리 내용 링크 주석 제공
-- =============================================================================

-- 실제 운영 환경에서는 아래 명령어로 JSON 파일 내용을 로드:
-- UPDATE metadata_standards
--   SET schema_json = pg_read_file('/path/to/standards/datacite_4_5.json')::jsonb
--   WHERE code = 'DATACITE_4_5';

-- 추가 크로스워크 매핑 예시 (DataCite ↔ Dublin Core)
-- (metadata_standards 테이블의 id는 실제 uuid로 교체 필요)

/*
INSERT INTO field_mappings (source_standard_id, source_field, target_standard_id, target_field, mapping_type, mapping_notes)
SELECT
    s.id, 'Creator', t.id, 'dc:creator', 'exact', 'DataCite Creator → Dublin Core creator'
FROM metadata_standards s, metadata_standards t
WHERE s.code = 'DATACITE_4_5' AND t.code = 'DUBLIN_CORE';

INSERT INTO field_mappings (source_standard_id, source_field, target_standard_id, target_field, mapping_type, mapping_notes)
SELECT
    s.id, 'Title', t.id, 'dc:title', 'exact', 'DataCite Title → Dublin Core title'
FROM metadata_standards s, metadata_standards t
WHERE s.code = 'DATACITE_4_5' AND t.code = 'DUBLIN_CORE';

INSERT INTO field_mappings (source_standard_id, source_field, target_standard_id, target_field, mapping_type, mapping_notes)
SELECT
    s.id, 'Subject', t.id, 'dc:subject', 'exact', 'DataCite Subject → Dublin Core subject (AGROVOC 권장)'
FROM metadata_standards s, metadata_standards t
WHERE s.code = 'DATACITE_4_5' AND t.code = 'DUBLIN_CORE';

INSERT INTO field_mappings (source_standard_id, source_field, target_standard_id, target_field, mapping_type, mapping_notes)
SELECT
    s.id, 'Description', t.id, 'dc:description', 'exact', 'DataCite Description(Abstract) → Dublin Core description'
FROM metadata_standards s, metadata_standards t
WHERE s.code = 'DATACITE_4_5' AND t.code = 'DUBLIN_CORE';

INSERT INTO field_mappings (source_standard_id, source_field, target_standard_id, target_field, mapping_type, mapping_notes)
SELECT
    s.id, 'creator', t.id, 'ags:creatorPersonal', 'partial', 'Harvard Dataverse author → AgMES creatorPersonal (개인 저자의 경우)'
FROM metadata_standards s, metadata_standards t
WHERE s.code = 'HARVARD_DATAVERSE' AND t.code = 'AGMES_1_1';
*/
