create or replace package backup is

    -- Synchonizes the db with it's backup counter part
    procedure propagate_changes;
    procedure propagate_user_deletions;
    procedure propagate_user_changes;
    procedure propagate_review_changes;

end backup;
/
