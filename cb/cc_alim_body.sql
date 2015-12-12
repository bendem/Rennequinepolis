create or replace package body movie_alim is

    procedure send_copies_of_all
    is
    begin
        null;
    exception
        when others then
            dbms_output.put_line(sqlerrm);
    end;

    procedure send_movie(
        p_id movies.movie_id%type)
    is
    begin
        insert into movies@link.cc values (
            select XMLElement("movie",
                XMLForest(
                    movie_id as "id",
                    movie_title as "title",
                    movie_original_title as "original_title",
                    movie_release_date as "release_date",
                    status_name as "status",
                    certification_name as "certification",
                    movie_vote_avg as "vote_average",
                    movie_vote_count as "vote_count",
                    movie_runtime as "runtime",
                    image as "poster",
                    movie_budget as "budget",
                    movie_revenue as "revenue",
                    movie_homepage as "homepage",
                    movie_tagline as "tagline",
                    movie_overview as "overview"
                ), (
                    select XMLAgg(
                        XMLElement("actor",
                            XMLForest(
                                person_id as "id",
                                person_name as "name",
                                image as "picture",
                                character_name as "character_name"
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
                                person_id as "id",
                                person_name as "name",
                                image as "picture"
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
                                rating as "rating",
                                creation_date as "creation_date",
                                content as "content"
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
            where movie_id = p_id
        );
    exception
        when others then
            dbms_output.put_line(sqlerrm);
    end;

end movie_alim;
/


-- select  XMLAgg(XMLElement("copy",
--                     XMLForest(
--                         copy_id as "id"
--                     )
--                 from copies where movie_id =
--                 ))
