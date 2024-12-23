DROP FUNCTION IF EXISTS create_tables;
CREATE OR REPLACE FUNCTION create_tables(
) RETURNS integer AS $$
BEGIN
    DROP TABLE IF EXISTS map_positions;
    CREATE TABLE map_positions (
        id integer,
        colIdx integer,
        rowIDx integer,
        height integer,
        path_source_ids integer[],
        trail_head_ids integer[]
    );

    DROP TABLE IF EXISTS paths;
    CREATE TABLE paths (
        position_id integer,
        path_count integer,
        trail_head_id integer
    );
    return 0;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS insert_map;
CREATE OR REPLACE FUNCTION insert_map(
    map text
) RETURNS integer AS $$
DECLARE ch char;
DECLARE strRow varchar;
DECLARE colI integer := 0;
DECLARE rowI integer := 0;
DECLARE width integer := 0;
DECLARE heightVal integer:= 0;
BEGIN
    PERFORM create_tables();    
    FOREACH strRow IN ARRAY regexp_split_to_array(map, '\n') LOOP
        width := LENGTH(strRow);
        FOREACH ch IN ARRAY regexp_split_to_array(strRow, '') LOOP            
            IF ch <> ' ' THEN
                IF ch = '.' THEN
                    heightVal := -10;
                ELSE
                    heightVal := CAST(ch AS INTEGER);
                END IF;
                INSERT INTO map_positions (id, colIdx, rowIdx, height) VALUES (rowI * width + colI, colI, rowI, heightVal);
                colI := colI + 1;
            END IF;
        END LOOP;
        rowI := rowI + 1;
        colI := 0;
    END LOOP;
    return 0;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS compute_trailheads;
CREATE OR REPLACE FUNCTION compute_trailheads() RETURNS integer AS $$
DECLARE heightIdx integer := 0;
BEGIN
    UPDATE map_positions mp SET path_source_ids =
        (SELECT array_agg(mp_source.id) FROM map_positions mp_source
            WHERE
                     mp_source.height = mp.height - 1
                AND (
                       (mp_source.colIdx=mp.colIdx + 1 AND mp_source.rowIdx=mp.rowIdx)
                    OR (mp_source.colIdx=mp.colIdx - 1 AND mp_source.rowIdx=mp.rowIdx)
                    OR (mp_source.colIdx=mp.colIdx AND mp_source.rowIdx=mp.rowIdx - 1)
                    OR (mp_source.colIdx=mp.colIdx AND mp_source.rowIdx=mp.rowIdx + 1)
                )
            GROUP BY mp.id
        );

    -- INTIALIZE for height 1, which has the path_source_ids == trail_head_ids
    UPDATE map_positions mp SET trail_head_ids = ARRAY[id] WHERE height = 0;
    UPDATE map_positions mp SET trail_head_ids = path_source_ids WHERE height = 1;

    FOR heightIdx IN 2..9 LOOP
        UPDATE map_positions mp SET trail_head_ids =
        (
            SELECT array_agg(mp_source_d.trail_head_ids) FROM (
                SELECT DISTINCT unnest(mp_source.trail_head_ids) as trail_head_ids FROM map_positions mp_source
                    WHERE
                        mp_source.id = ANY (mp.path_source_ids)
            ) AS mp_source_d
        )        
        WHERE mp.height = heightIdx;
    END LOOP;

    INSERT INTO paths (position_id, path_count, trail_head_id) (SELECT id position_id, 1, id trail_head_id FROM map_positions WHERE height = 0);

    FOR heightIdx IN 1..9 LOOP
        INSERT INTO paths (position_id, path_count, trail_head_id) (
            SELECT mp.id, SUM(path_count), paths.trail_head_id as path_count FROM  
                map_positions mp
                INNER JOIN paths on paths.position_id = ANY(mp.path_source_ids)
                WHERE mp.height = heightIdx
            GROUP BY mp.id, paths.trail_head_id
        );
    END LOOP;

    RETURN 0;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_trailheadscore;
CREATE OR REPLACE FUNCTION get_trailheadscore(
    map text
) RETURNS integer AS $$
BEGIN
    PERFORM create_tables();    
    PERFORM insert_map(map);
    PERFORM compute_trailheads();
    
    RETURN COALESCE((SELECT SUM(cardinality(ARRAY(SELECT DISTINCT UNNEST(trail_head_ids)))) FROM map_positions 
         WHERE height = 9
        ),0);
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_trailheadrating_by_trailhead;
CREATE OR REPLACE FUNCTION get_trailheadrating_by_trailhead(
    th_id integer
) RETURNS integer AS $$
BEGIN

    RETURN COALESCE(
        (SELECT SUM(path_count) FROM paths
            INNER JOIN map_positions mp on paths.position_id = mp.id
            WHERE mp.height = 9 AND paths.trail_head_id = th_id)
    ,0);

END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_trailheadrating;
CREATE OR REPLACE FUNCTION get_trailheadrating(
    map text
) RETURNS integer AS $$
BEGIN
    PERFORM create_tables();    
    PERFORM insert_map(map);
    PERFORM compute_trailheads();
    
    RETURN (SELECT SUM(get_trailheadrating_by_trailhead(id)) FROM map_positions WHERE height = 0);    
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test_day10_part1(
) RETURNS SETOF TEXT AS $$
BEGIN        
    RETURN NEXT is(get_trailheadscore('0'), 0);
    RETURN NEXT is(get_trailheadscore('0123456789'), 1);
    RETURN NEXT is(get_trailheadscore(
'0123456789
 5555595555'
        ), 1);
    RETURN NEXT is(get_trailheadscore(
'0123456789
 5555987555'
        ), 2);
RETURN NEXT is(get_trailheadscore(
'10..9..
 2...8..
 3...7..
 4567654
 ...8..3
 ...9..2
 .....01'
        ), 3);
-- RETURN NEXT is(get_trailheadscore(
-- '<content excluded>'
--         ), 0);
-- RETURN NEXT is(get_trailheadscore(
-- '<content excluded>'
--         ), 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test_day10_part2(
) RETURNS SETOF TEXT AS $$
BEGIN        
    RETURN NEXT is(get_trailheadrating('0'), 0);
    RETURN NEXT is(get_trailheadrating(
'.....0.
 ..4321.
 ..5..2.
 ..6543.
 ..7..4.
 ..8765.
 ..9....'), 3);
    RETURN NEXT is(get_trailheadrating(
'.......
 ..43210
 ..5..2.
 ..6543.
 ..7..4.
 ..8765.
 ..9....'), 3);
    RETURN NEXT is(get_trailheadrating(
'10...0.
 234321.
 ..5..2.
 ..6543.
 ..7..4.
 ..8765.
 ..9....'), 4);
    RETURN NEXT is(get_trailheadrating(
'.....0.
 ..4321.
 ..5432.
 ..6543.
 ..7..4.
 ..8765.
 ..9....'), 11);
    RETURN NEXT is(get_trailheadrating(
'012345
 123456
 234567
 345678
 4.6789
 56789.'), 227);
--     RETURN NEXT is(get_trailheadrating(
-- '<content excluded>'), 0);
--     RETURN NEXT is(get_trailheadrating(
-- '<content excluded>'), 0);
END;
$$ LANGUAGE plpgsql;

SELECT runtests( );
