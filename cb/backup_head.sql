create or replace package backup is

    -- Synchronizes the db with its backup counter part.
    --
    -- This is a procedure wrapping all below procedures in a transaction.
    procedure propagate_changes;

    -- Deletes users deleted from this db in its backup counter part.
    procedure propagate_user_deletions;

    -- Deletes copies deleted from this db in its backup counter part.
    procedure propagate_copy_deletions;

    -- Synchronizes changes made to users in the db with its backup counter
    -- part.
    procedure propagate_user_changes;

    -- Synchronizes changes made to reviews in the db with its backup counter
    -- part.
    procedure propagate_review_changes;

    -- Synchronizes changes made to the movie copies in the db with its backup
    -- counter part.
    procedure propagate_copy_changes;

    -- Synchronizes changes made to the movie in the db with its backup counter
    -- part.
    procedure propagate_movie_changes;

    -- Wraps propagate_review_changes and propagate_copy_changes in an
    -- autonomous transaction.
    --
    -- Used in cbb.link_check.check_link_available to propagate changes
    -- when cb comes back up without messing with the current transaction.
    procedure sync_propagation;

end backup;
/
