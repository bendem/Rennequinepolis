create or replace package backup is

    -- Synchonizes the db with it's backup counter part
    procedure do_the_thing;
    procedure delete_them_userz;
    procedure copy_them_userz;
    procedure copy_them_reviewz;

end backup;
/
