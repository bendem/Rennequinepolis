create or replace package body cc_alim is

    procedure send_copies_of_all
    is
        type copies_t is table of copies%rowtype;
        v_copies copies_t;
    begin
        delete from copies extext where (movie_id,copy_id) in (select movie_id, copy_id from copies ext where
        rownum < round(abs(sys.dbms_random.value(0, (select count(*) from copies int where int.movie_id = ext.movie_id)/2) + 1))
        and ext.movie_id = extext.movie_id)
        returning bulk collect into v_copies;

        insert into cc_queue
            select 'copy', XMLAgg(XMLElement("copy",
                XMLForest(
                    copy_id "copy_id",
                    movie_id "movie_id"
                )
            )) from table(v_copies);
    exception
        when others then
            dbms_output.put_line(sqlerrm);
    end;

    procedure send_copies(
        p_id movies.movie_id%type)
    is
        type copies_t is table of copies%rowtype;
        v_copies copies_t;
    begin
        delete from copies where movie_id = p_id and
        rownum < round(abs(sys.dbms_random.value(0, (select count(*) from copies where movie_id = p_id)/2) + 1
        returning bulk collect into v_copies;


        insert into cc_queue
            select 'copy', XMLAgg(XMLElement("copy",
                XMLForest(
                    copy_id "copy_id",
                    movie_id "movie_id"
                )
            )) from table(v_copies);

    exception
      when others then
        null;
    end;

    procedure send_movie(
        p_id movies.movie_id%type)
    is
    begin
        insert into cc_queue
            select 'movie', XMLElement("movie",
                XMLForest(
                    movie_id             "id",
                    movie_title          "title",
                    movie_original_title "original_title",
                    movie_release_date   "release_date",
                    status_name          "status",
                    certification_name   "certification",
                    movie_vote_avg       "vote_average",
                    movie_vote_count     "vote_count",
                    movie_runtime        "runtime",
                    image                "poster",
                    movie_budget         "budget",
                    movie_revenue        "revenue",
                    movie_homepage       "homepage",
                    movie_tagline        "tagline",
                    movie_overview       "overview"
                ), (
                    select XMLAgg(
                        XMLElement("actor",
                            XMLForest(
                                person_id      "id",
                                person_name    "name",
                                image          "picture",
                                character_name "character_name"
                            )
                        )
                    )
                    from characters
                    natural join people
                    left join images on (person_profile_id = image_id)
                    where movie_id = p_id
                ), (
                    select XMLAgg(
                        XMLElement("director",
                            XMLForest(
                                person_id   "id",
                                person_name "name",
                                image       "picture"
                            )
                        )
                    )
                    from movies_directors
                    natural join people
                    left join images on (person_profile_id = image_id)
                    where movie_id = p_id
                ), (
                    select XMLAgg(XMLElement("production_company", production_company_name))
                    from production_companies
                    natural join movies_production_companies
                    where movie_id = p_id
                ), (
                    select XMLAgg(XMLElement("production_country", production_country_name))
                    from production_countries
                    natural join movies_production_countries
                    where movie_id = p_id
                ), (
                    select XMLAgg(XMLElement("genre", genre_name))
                    from genres natural join movies_genres where movie_id = p_id
                ), (
                    select XMLAgg(
                        XMLElement("review",
                            XMLForest(
                                rating        "rating",
                                creation_date "creation_date",
                                content       "content"
                            )
                        )
                    )
                    from reviews
                    where movie_id = p_id and backup_flag <> 2
                ), (
                    select XMLAgg(XMLElement("spoken_language", spoken_language_name))
                    from spoken_languages
                    natural join movies_spoken_languages
                    where movie_id = p_id
                )
            )
            from movies m
            left join certifications on (m.movie_certification_id = certification_id)
            left join statuses on (m.movie_status_id = status_id)
            left join images on (m.movie_poster_id = image_id)
            where movie_id = p_id;
    exception
        when others then
            dbms_output.put_line(sqlerrm);
    end;

end cc_alim;
/
