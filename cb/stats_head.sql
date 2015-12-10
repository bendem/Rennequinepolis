create or replace package stats is

    -- Analyses the movies_ext table to generate a statistic report
    -- of its data.
    -- @param p_file the name of the report file where the results will be written
    procedure analyze_table(
        p_file varchar2 default 'AnalysisResult.txt');

end stats;
/
