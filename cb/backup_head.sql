create or replace package backup is

    -- Synchonizes the db with it's backup counter part
    procedure propagate_changes;
    procedure propagate_user_deletions;
    procedure propagate_user_changes;
    procedure propagate_review_changes;
    procedure propagate_copy_changes;
    procedure propagate_movie_changes;

    procedure sync_propagation;

end backup;
/
