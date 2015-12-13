create or replace package body cc_alim is

    procedure send_copies_of_all
    is
        v_copies management.copies_t;
        movie_ids number_t;
    begin
        select movie_id bulk collect into movie_ids from movies;

        for i in movie_ids.first..movie_ids.last loop
            send_copies(movie_ids(i));
        end loop;

        cb_pull.pull_movies@link.cc;
        cb_pull.pull_copies@link.cc;
        commit;
    exception
        when others then
            rollback;
            logging.e('Failed to send weekly copies: ' || sqlerrm);
            raise;
    end;

    procedure send_copies(
        p_id movies.movie_id%type)
    is
        v_copies management.copies_t;
    begin
        select movie_id, copy_id bulk collect into v_copies
        from copies
        where movie_id = p_id
            and backup_flag <> 2
            and rownum < round(sys.dbms_random.value(0, (
                select count(*)
                from copies
                where movie_id = p_id
                    and backup_flag <> 2
            ) / 2)) + 1;

        if v_copies.count = 0 then
            return;
        end if;

        if not cb_pull.movie_exists@link.cc(p_id) then
            send_movie(p_id);
        end if;

        management.remove_copies(v_copies);

        forall i in indices of v_copies insert into cc_queue values(
            'copy',
            xmlelement("copy",
                xmlforest(
                    v_copies(i).copy_id "copy_id",
                    v_copies(i).movie_id "movie_id")));
    exception
        when others then
            logging.e('Failed to send copies of movie ' || p_id || ': ' || sqlerrm);
            raise;
    end;

    procedure send_movie(
        p_id movies.movie_id%type)
    is
    begin
        insert into cc_queue
            select 'movie', xmlelement("movie",
                xmlforest(
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
                    select xmlagg(
                        xmlelement("actor",
                            xmlforest(
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
                    select xmlagg(
                        xmlelement("director",
                            xmlforest(
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
                    select xmlagg(xmlelement("production_company", production_company_name))
                    from production_companies
                    natural join movies_production_companies
                    where movie_id = p_id
                ), (
                    select xmlagg(xmlelement("production_country", production_country_name))
                    from production_countries
                    natural join movies_production_countries
                    where movie_id = p_id
                ), (
                    select xmlagg(xmlelement("genre", genre_name))
                    from genres natural join movies_genres where movie_id = p_id
                ), (
                    select xmlagg(
                        xmlelement("review",
                            xmlforest(
                                rating        "rating",
                                creation_date "creation_date",
                                content       "content"
                            )
                        )
                    )
                    from reviews
                    where movie_id = p_id and backup_flag <> 2
                ), (
                    select xmlagg(xmlelement("spoken_language", spoken_language_name))
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
            logging.e('Failed to send movie ' || p_id || ': ' || sqlerrm);
            raise;
    end;

end cc_alim;
/
