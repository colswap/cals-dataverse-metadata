-- =============================================================================
-- 서울대학교 농업생명과학대학 (CALS) 연구 데이터 통합관리 플랫폼
-- Migration: 001_init.sql
-- Created: 2026-02-24
-- Schema Version: 1.0.0
-- Standards: DataCite 4.5, Dublin Core, Harvard Dataverse, AGRIS AP,
--            AgMES, AI Hub KR, SmartFarm KR, Wageningen WUR
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";       -- UUID 생성
CREATE EXTENSION IF NOT EXISTS "pg_trgm";         -- 한국어 포함 텍스트 퍼지검색
CREATE EXTENSION IF NOT EXISTS "unaccent";        -- 발음구별부호 제거 검색

-- ---------------------------------------------------------------------------
-- ENUM Types
-- ---------------------------------------------------------------------------

CREATE TYPE resource_type_general AS ENUM (
    'Dataset', 'Collection', 'DataPaper', 'Software',
    'Image', 'Audiovisual', 'Text', 'Other'
);

CREATE TYPE access_type AS ENUM (
    'open', 'restricted', 'embargoed', 'closed'
);

CREATE TYPE dataset_status AS ENUM (
    'draft', 'under_review', 'published', 'deprecated', 'withdrawn'
);

CREATE TYPE identifier_type AS ENUM (
    'DOI', 'Handle', 'URL', 'CALS-Internal', 'arXiv', 'PMID', 'URN'
);

CREATE TYPE contributor_role AS ENUM (
    'ContactPerson', 'DataCollector', 'DataCurator', 'DataManager',
    'ProjectLeader', 'ProjectMember', 'Researcher', 'Supervisor',
    'FieldTechnician', 'LabTechnician', 'Other'
);

-- ---------------------------------------------------------------------------
-- 1. datasets (메타데이터 핵심 테이블)
--    JSONB로 유연한 메타데이터 스키마 수용
--    출처: CALS Metadata Schema v1.0 / DataCite 4.5 / Dublin Core
-- ---------------------------------------------------------------------------
CREATE TABLE datasets (
    -- 시스템 식별자
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    internal_id     TEXT UNIQUE NOT NULL,           -- CALS 내부 ID (예: CALS-2026-00001)

    -- 핵심 인용 메타데이터 (DataCite Property 1~5, 10 Mandatory)
    doi             TEXT UNIQUE,                    -- DataCite Property 1: Identifier (DOI)
    title           TEXT NOT NULL,                  -- DataCite Property 3 / DC title
    title_en        TEXT,
    publication_year SMALLINT,                      -- DataCite Property 5
    resource_type   resource_type_general NOT NULL DEFAULT 'Dataset',  -- DataCite Property 10
    resource_type_specific TEXT,                    -- 세부 유형 자유 기술

    -- 접근·권리 정보
    access_type     access_type NOT NULL DEFAULT 'private',  -- DataCite Property 16
    license         TEXT,                           -- 예: CC BY 4.0
    license_uri     TEXT,
    embargo_end_date DATE,

    -- 버전 및 크기
    version         TEXT DEFAULT '1.0',             -- DataCite Property 15
    file_size_bytes BIGINT,                         -- DataCite Property 13

    -- 데이터셋 상태
    status          dataset_status NOT NULL DEFAULT 'draft',

    -- JSONB 확장 메타데이터 블록
    -- 출처: CALS Metadata Schema v1.0 (schema/cals_metadata_schema.json)
    metadata        JSONB NOT NULL DEFAULT '{}',
    -- metadata 구조:
    -- {
    --   "description": [...],         DataCite P17 / DC description
    --   "subject": [...],             DataCite P6 / AGROVOC 통제어휘
    --   "language": [...],            DataCite P9 / ISO 639-1
    --   "format": [...],              DataCite P14 / MIME type
    --   "date": {...},                DataCite P8 (created/modified/issued/collected)
    --   "related_identifier": [...],  DataCite P12
    --   "geo_location": [...],        DataCite P18 / WGS84 좌표
    --   "provenance": {...},          DC dcterms:provenance
    --   "administrative": {...}       내부 관리 정보
    -- }

    -- CALS 농업생명과학 특화 메타데이터 (JSONB)
    -- 출처: 스마트팜 데이터마켓, AI Hub KR, Harvard Dataverse Life Sciences, AgMES
    cals_metadata   JSONB NOT NULL DEFAULT '{}',
    -- cals_metadata 구조:
    -- {
    --   "department": "...",           학과
    --   "lab_group": "...",            연구실
    --   "research_domain": [...],      연구 분야
    --   "agriculture_extension": {     농업생명과학 확장
    --     "crop": [...],                 작물 정보 (학명, AGROVOC URI, NCBI TaxID)
    --     "organism": [...],             생물종
    --     "experiment_type": [...],      실험 유형
    --     "treatment": [...],            처리 인자
    --     "smart_farm": {...},           스마트팜 특화
    --     "field_location": {...},       실험지 정보
    --     "measurement_metadata": {...}  측정·분석 방법
    --   },
    --   "ai_training_metadata": {...}, AI Hub KR 품질관리 가이드라인 v3.1
    --   "retention_policy": {...}      보존 정책
    -- }

    -- 검색 최적화용 tsvector (GIN 인덱스)
    search_vector   TSVECTOR,

    -- 감사 로그
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      TEXT,
    updated_by      TEXT
);

COMMENT ON TABLE datasets IS '서울대학교 CALS 연구 데이터 통합관리 플랫폼 - 핵심 메타데이터 테이블 (Schema v1.0, DataCite 4.5 / Dublin Core / AGRIS AP 기반)';
COMMENT ON COLUMN datasets.metadata IS 'JSONB: 표준 메타데이터 확장 블록 (description, subject, language, format, date, related_identifier, geo_location, provenance)';
COMMENT ON COLUMN datasets.cals_metadata IS 'JSONB: CALS 농업생명과학 특화 메타데이터 (department, research_domain, agriculture_extension, ai_training_metadata 등)';

-- ---------------------------------------------------------------------------
-- 2. creators (저자/생성자 테이블)
--    출처: DataCite Property 2 / AGRIS AP dc:creator / AgMES ags:creatorPersonal
-- ---------------------------------------------------------------------------
CREATE TABLE creators (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id      UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    display_order   SMALLINT NOT NULL DEFAULT 0,     -- 저자 순서 (DataCite: 순서 의미 있음)

    name            TEXT NOT NULL,                   -- 성명
    name_en         TEXT,
    name_type       TEXT NOT NULL DEFAULT 'Personal' CHECK (name_type IN ('Personal', 'Organizational')),

    -- 식별자 (ORCID 권장)
    identifier      TEXT,                            -- ORCID, ISNI 등
    identifier_scheme TEXT DEFAULT 'ORCID',          -- DataCite creatorNameIdentifierScheme

    -- 소속
    affiliation     JSONB DEFAULT '{}',
    -- affiliation: {"name": "...", "name_en": "...", "ror_id": "https://ror.org/..."}

    email           TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE creators IS '데이터셋 생성자 테이블 (DataCite Property 2 / AgMES ags:creatorPersonal)';
COMMENT ON COLUMN creators.display_order IS 'DataCite 명세: 저자 순서는 의미를 가짐';

-- ---------------------------------------------------------------------------
-- 3. contributors (기여자 테이블)
--    출처: DataCite Property 7 / Wageningen Contributor
-- ---------------------------------------------------------------------------
CREATE TABLE contributors (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id      UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,

    name            TEXT NOT NULL,
    name_en         TEXT,
    role            contributor_role NOT NULL DEFAULT 'Researcher',

    identifier      TEXT,
    identifier_scheme TEXT DEFAULT 'ORCID',
    affiliation     TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE contributors IS '데이터셋 기여자 테이블 (DataCite Property 7 / Wageningen WUR Contributor)';

-- ---------------------------------------------------------------------------
-- 4. funding_references (연구비 지원 정보)
--    출처: DataCite Property 19 / Wageningen DMP
-- ---------------------------------------------------------------------------
CREATE TABLE funding_references (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id              UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,

    funder_name             TEXT NOT NULL,           -- 지원 기관명 (예: 한국연구재단)
    funder_identifier       TEXT,                    -- Crossref Funder ID / ROR
    funder_identifier_type  TEXT DEFAULT 'Crossref Funder ID',

    award_number            TEXT,                    -- 과제번호
    award_title             TEXT,                    -- 과제명
    award_uri               TEXT,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE funding_references IS '연구비 지원 정보 테이블 (DataCite Property 19). 한국연구재단, 농촌진흥청, 농림부 과제번호 관리.';

-- ---------------------------------------------------------------------------
-- 5. metadata_standards (조사된 메타데이터 표준 레퍼런스 테이블)
--    출처: 본 프로젝트 조사 결과 (standards/ 디렉토리)
-- ---------------------------------------------------------------------------
CREATE TABLE metadata_standards (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code            TEXT UNIQUE NOT NULL,            -- 내부 코드 (예: DATACITE_4_5)
    name            TEXT NOT NULL,                   -- 표준명
    version         TEXT,
    institution     TEXT NOT NULL,                   -- 관리 기관
    url             TEXT,                            -- 공식 URL
    retrieved_at    DATE,
    status          TEXT DEFAULT 'active' CHECK (status IN ('active', 'deprecated', 'pending')),
    notes           TEXT,
    schema_json     JSONB                            -- standards/ 디렉토리 JSON 전체 내용 (선택)
);

COMMENT ON TABLE metadata_standards IS '조사된 메타데이터 표준 레퍼런스 테이블 (DataCite, Dublin Core, AGRIS AP, AgMES, AI Hub KR, SmartFarm KR, Wageningen WUR)';

-- ---------------------------------------------------------------------------
-- 6. field_mappings (표준 간 필드 매핑 테이블)
--    출처: DataCite↔Dublin Core↔Harvard Dataverse 크로스워크
-- ---------------------------------------------------------------------------
CREATE TABLE field_mappings (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_standard_id UUID NOT NULL REFERENCES metadata_standards(id),
    source_field    TEXT NOT NULL,                   -- 출처 표준 필드명
    target_standard_id UUID NOT NULL REFERENCES metadata_standards(id),
    target_field    TEXT NOT NULL,                   -- 대상 표준 필드명
    mapping_type    TEXT DEFAULT 'exact' CHECK (mapping_type IN ('exact', 'partial', 'approximate', 'none')),
    mapping_notes   TEXT
);

COMMENT ON TABLE field_mappings IS '메타데이터 표준 간 필드 크로스워크 (DataCite↔Dublin Core↔AGRIS AP↔CALS 매핑)';

-- ---------------------------------------------------------------------------
-- 7. smart_farm_observations (스마트팜 센서 시계열 데이터)
--    출처: 농림축산식품부 스마트팜 데이터마켓 / 스마트팜코리아
--           https://www.data.go.kr/data/15121325/openapi.do
-- ---------------------------------------------------------------------------
CREATE TABLE smart_farm_observations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id      UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    observed_at     TIMESTAMPTZ NOT NULL,            -- 측정 일시

    -- 내부환경 (스마트팜 데이터마켓 환경 데이터 항목)
    temp_internal   NUMERIC(5,2),                    -- 내부온도 (°C)
    humidity_internal NUMERIC(5,2),                  -- 내부습도 (%RH)
    co2_ppm         NUMERIC(7,2),                    -- CO2 농도 (ppm)
    illuminance_lux NUMERIC(10,2),                   -- 조도 (lux)
    solar_radiation_wm2 NUMERIC(8,2),                -- 일사량 (W/m²)

    -- 토양 (스마트팜 데이터마켓 토양 데이터 항목)
    soil_temp       NUMERIC(5,2),                    -- 토양온도 (°C)
    soil_moisture   NUMERIC(5,2),                    -- 토양수분 (%)
    soil_ec         NUMERIC(6,3),                    -- 토양EC (mS/cm)
    soil_ph         NUMERIC(4,2),                    -- 토양pH

    -- 양액제어 (스마트팜 데이터마켓 제어 데이터 항목)
    nutrient_ec     NUMERIC(6,3),                    -- 양액EC (mS/cm)
    nutrient_ph     NUMERIC(4,2),                    -- 양액pH

    -- 확장 측정값 (JSONB - 기타 센서 데이터)
    extra           JSONB DEFAULT '{}',

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE smart_farm_observations IS '스마트팜 IoT 센서 시계열 관측 데이터. 출처: 농림축산식품부 스마트팜 데이터마켓 (https://www.data.go.kr/data/15121325/openapi.do)';

-- ---------------------------------------------------------------------------
-- 8. growth_records (작물 생육 조사 기록)
--    출처: 스마트팜코리아 생육 데이터 / Harvard Dataverse Life Sciences
-- ---------------------------------------------------------------------------
CREATE TABLE growth_records (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id      UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    observed_at     DATE NOT NULL,                   -- 조사일

    growth_stage    TEXT,                            -- 생육단계 (발아/정식/개화/착과/수확)
    plant_height_cm NUMERIC(7,2),                    -- 초장 (cm)
    leaf_count      SMALLINT,                        -- 엽수 (매)
    leaf_area_cm2   NUMERIC(10,2),                   -- 엽면적 (cm²)
    stem_diameter_mm NUMERIC(6,2),                   -- 줄기직경 (mm)
    fruit_count     SMALLINT,                        -- 착과수 (개)
    yield_g         NUMERIC(10,2),                   -- 수확량 (g/주)
    sugar_brix      NUMERIC(5,2),                    -- 당도 (°Brix)

    extra           JSONB DEFAULT '{}',              -- 작물별 추가 생육 지표

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE growth_records IS '작물 생육 조사 기록. 출처: 스마트팜코리아 / Harvard Dataverse Life Sciences ISA-Tab';

-- ---------------------------------------------------------------------------
-- 9. audit_log (감사 로그)
-- ---------------------------------------------------------------------------
CREATE TABLE audit_log (
    id              BIGSERIAL PRIMARY KEY,
    table_name      TEXT NOT NULL,
    record_id       UUID NOT NULL,
    action          TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data        JSONB,
    new_data        JSONB,
    changed_by      TEXT,
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE audit_log IS '데이터셋 메타데이터 변경 이력 감사 로그';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- datasets 검색 인덱스
CREATE INDEX idx_datasets_doi              ON datasets (doi) WHERE doi IS NOT NULL;
CREATE INDEX idx_datasets_status           ON datasets (status);
CREATE INDEX idx_datasets_resource_type    ON datasets (resource_type);
CREATE INDEX idx_datasets_access_type      ON datasets (access_type);
CREATE INDEX idx_datasets_publication_year ON datasets (publication_year);

-- JSONB GIN 인덱스 (metadata 전체 검색)
CREATE INDEX idx_datasets_metadata_gin     ON datasets USING GIN (metadata);
CREATE INDEX idx_datasets_cals_metadata_gin ON datasets USING GIN (cals_metadata);

-- JSONB 특정 경로 인덱스 (자주 쿼리되는 필드)
-- 연구 분야 검색
CREATE INDEX idx_cals_research_domain
    ON datasets USING GIN ((cals_metadata -> 'research_domain'));

-- 작물 학명 검색 (AgMES ags:scientificName)
CREATE INDEX idx_cals_crop
    ON datasets USING GIN ((cals_metadata #> '{agriculture_extension, crop}'));

-- 스마트팜 시설 유형 검색
CREATE INDEX idx_cals_smart_farm_facility
    ON datasets ((cals_metadata #>> '{agriculture_extension, smart_farm, facility_type}'));

-- 주제어 검색 (AGROVOC)
CREATE INDEX idx_metadata_subject
    ON datasets USING GIN ((metadata -> 'subject'));

-- 수집 기간 검색
CREATE INDEX idx_metadata_collected_start
    ON datasets ((metadata #>> '{date, collected, start}'));
CREATE INDEX idx_metadata_collected_end
    ON datasets ((metadata #>> '{date, collected, end}'));

-- 지리 정보 검색 (GeoLocation place)
CREATE INDEX idx_metadata_geolocation
    ON datasets USING GIN ((metadata -> 'geo_location'));

-- 전문 검색 인덱스 (한국어 tsvector)
CREATE INDEX idx_datasets_search_vector    ON datasets USING GIN (search_vector);

-- 관련 테이블 인덱스
CREATE INDEX idx_creators_dataset_id       ON creators (dataset_id);
CREATE INDEX idx_creators_identifier       ON creators (identifier) WHERE identifier IS NOT NULL;
CREATE INDEX idx_contributors_dataset_id   ON contributors (dataset_id);
CREATE INDEX idx_funding_dataset_id        ON funding_references (dataset_id);
CREATE INDEX idx_funding_award_number      ON funding_references (award_number) WHERE award_number IS NOT NULL;

-- 스마트팜 시계열 인덱스
CREATE INDEX idx_sfo_dataset_id            ON smart_farm_observations (dataset_id);
CREATE INDEX idx_sfo_observed_at           ON smart_farm_observations (dataset_id, observed_at DESC);
CREATE INDEX idx_growth_dataset_id         ON growth_records (dataset_id);
CREATE INDEX idx_growth_observed_at        ON growth_records (dataset_id, observed_at DESC);

-- 감사 로그 인덱스
CREATE INDEX idx_audit_record_id           ON audit_log (record_id);
CREATE INDEX idx_audit_changed_at          ON audit_log (changed_at DESC);

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_datasets_updated_at
    BEFORE UPDATE ON datasets
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- 전문 검색 벡터 자동 갱신 (한국어 제목+영문 제목+내부ID 대상)
CREATE OR REPLACE FUNCTION fn_update_search_vector()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.search_vector =
        setweight(to_tsvector('simple', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.title_en, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(NEW.internal_id, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(
            NEW.metadata #>> '{description, 0, value}', ''
        )), 'D');
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_datasets_search_vector
    BEFORE INSERT OR UPDATE ON datasets
    FOR EACH ROW EXECUTE FUNCTION fn_update_search_vector();

-- 감사 로그 자동 기록 (datasets 테이블)
CREATE OR REPLACE FUNCTION fn_audit_datasets()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_data, changed_by)
        VALUES ('datasets', NEW.id, 'INSERT', to_jsonb(NEW), NEW.created_by);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by)
        VALUES ('datasets', NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), NEW.updated_by);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data)
        VALUES ('datasets', OLD.id, 'DELETE', to_jsonb(OLD));
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_datasets_audit
    AFTER INSERT OR UPDATE OR DELETE ON datasets
    FOR EACH ROW EXECUTE FUNCTION fn_audit_datasets();

-- =============================================================================
-- SEED: metadata_standards 기준 데이터
-- =============================================================================
INSERT INTO metadata_standards (code, name, version, institution, url, retrieved_at, status, notes) VALUES
(
    'DATACITE_4_5',
    'DataCite Metadata Schema',
    '4.5',
    'DataCite e.V.',
    'https://datacite-metadata-schema.readthedocs.io/en/4.5/',
    '2026-02-24',
    'active',
    '6개 필수 속성: Identifier, Creator, Title, Publisher, PublicationYear, ResourceType. v4.5 신규: Instrument/StudyRegistration 유형, IsCollectedBy/Collects 관계유형, Publisher 식별자 지원.'
),
(
    'DUBLIN_CORE',
    'Dublin Core Metadata Initiative Terms (DCMI Terms)',
    '2020-01-20',
    'Dublin Core Metadata Initiative (DCMI)',
    'https://www.dublincore.org/specifications/dublin-core/dcmi-terms/',
    '2026-02-24',
    'active',
    'AGRIS AP, AgMES의 기반 표준. 15개 핵심 요소. Namespace: http://purl.org/dc/terms/'
),
(
    'HARVARD_DATAVERSE',
    'Harvard Dataverse Metadata Blocks',
    'Dataverse 6.x',
    'Harvard University IQSS',
    'https://guides.dataverse.org/en/latest/user/appendix.html',
    '2026-02-24',
    'active',
    'DDI Lite/2.5 Codebook + DataCite 4.5 + Dublin Core 기반. Life Sciences 블록은 ISA-Tab 기반. TSV 상세 명세는 research/pending_fao.md 참조.'
),
(
    'AGMES_1_1',
    'Agricultural Metadata Element Set (AgMES)',
    '1.1',
    'FAO (Food and Agriculture Organization)',
    'https://aims.fao.org/standards/agmes',
    '2026-02-24',
    'deprecated',
    '농업 특화 Dublin Core 확장 (ags: 네임스페이스). 공식 Deprecated. AGRIS AP와 함께 활용. 전체 namespace spec은 pending_fao.md 참조.'
),
(
    'AGRIS_AP',
    'AGRIS Application Profile',
    '2.0',
    'FAO - AGRIS International System',
    'https://www.fao.org/agris/',
    '2026-02-24',
    'active',
    'DC + AGLS + AgMES 기반 농업 문헌 메타데이터 교환 표준. LODE-BD M2B 최소요건 준수 권장. 전체 요소 목록은 pending_fao.md 참조.'
),
(
    'AIHUB_KR',
    '한국 AI Hub 데이터셋 메타데이터 / 인공지능 학습용 데이터 품질관리 가이드라인',
    'v3.1 (2024)',
    '한국지능정보사회진흥원 (NIA)',
    'https://aihub.or.kr/',
    '2026-02-24',
    'active',
    '845종+ AI 학습용 데이터 카탈로그. 필드: 구축년도, 데이터명, 분야, 유형, 소개, 링크.'
),
(
    'SMARTFARM_KR',
    '농림축산식품부 스마트팜 데이터마켓 / 스마트팜코리아',
    '2024',
    '농림축산식품부 / 스마트팜코리아',
    'https://www.smartfarmkorea.net/',
    '2026-02-24',
    'active',
    '환경(온도·습도·CO2·조도·토양수분)·제어(양액·광·관수)·생육·경영·이미지 데이터. IoT 표준화 진행 중(KISTI).'
),
(
    'WAGENINGEN_WUR',
    'Wageningen University & Research Yoda Metadata (DataCite 기반)',
    'Yoda@WUR 2024',
    'Wageningen University & Research Data Competence Centre (WDCC)',
    'https://www.wur.nl/en/value-creation-cooperation/collaborating-with-wur-1/wdcc/',
    '2026-02-24',
    'active',
    'DataCite 4.x 기반 Yoda 메타데이터. NARCIS 분야 분류. FAIR 원칙. 농업·식품·환경·건강 연구. DOI 자동 등록.'
);

-- =============================================================================
-- VIEWS (편의 조회용)
-- =============================================================================

-- 공개 데이터셋 목록 뷰 (검색 포털용)
CREATE OR REPLACE VIEW v_public_datasets AS
SELECT
    d.id,
    d.internal_id,
    d.doi,
    d.title,
    d.title_en,
    d.publication_year,
    d.resource_type,
    d.resource_type_specific,
    d.access_type,
    d.license,
    d.version,
    d.metadata -> 'description' AS descriptions,
    d.metadata -> 'subject'     AS subjects,
    d.metadata -> 'date'        AS dates,
    d.metadata -> 'geo_location' AS geo_locations,
    d.cals_metadata -> 'department'       AS department,
    d.cals_metadata -> 'research_domain'  AS research_domain,
    d.cals_metadata #> '{agriculture_extension, crop}' AS crops,
    d.cals_metadata #>> '{agriculture_extension, smart_farm, facility_type}' AS smart_farm_facility,
    d.created_at,
    d.updated_at
FROM datasets d
WHERE d.status = 'published'
  AND d.access_type IN ('open', 'restricted');

COMMENT ON VIEW v_public_datasets IS '공개 데이터셋 목록 (검색 포털 전용 뷰)';

-- 스마트팜 데이터셋 뷰
CREATE OR REPLACE VIEW v_smart_farm_datasets AS
SELECT
    d.id,
    d.internal_id,
    d.title,
    d.cals_metadata #>> '{agriculture_extension, smart_farm, facility_type}' AS facility_type,
    d.cals_metadata #> '{agriculture_extension, crop}'                        AS crops,
    d.cals_metadata #>> '{agriculture_extension, smart_farm, sampling_interval}' AS sampling_interval,
    d.cals_metadata #> '{agriculture_extension, smart_farm, sensor_types}'    AS sensor_types,
    d.metadata #>> '{date, collected, start}'                                 AS collected_start,
    d.metadata #>> '{date, collected, end}'                                   AS collected_end
FROM datasets d
WHERE d.cals_metadata #> '{agriculture_extension, smart_farm}' IS NOT NULL;

COMMENT ON VIEW v_smart_farm_datasets IS '스마트팜 데이터셋 목록 뷰';
