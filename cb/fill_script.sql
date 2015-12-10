begin
    management.add_user('username1', 'password1', 'Flohic',    'Erwan');
    management.add_user('username2', 'password2', 'Demarteau', 'Benjamin');
    management.add_user('username3', 'password3', 'Kamishin',  'Ilja');
    management.add_user('username4', 'password4', 'Seel',      'Oceane');
    management.add_user('username5', 'password5', 'Fink',      'Jerome');
    management.add_user('username6', 'password6', 'Marley',    'Bob');
    management.add_user('username7', 'password7', 'Morane',    'Bob');

    management.add_review('username1', 1, 1, 'Meh could have been better1');
    management.add_review('username2', 1, 2, 'Meh could have been better2');
    management.add_review('username3', 1, 3, 'Meh could have been better3');
    management.add_review('username4', 1, 4, 'Meh could have been better4');
    management.add_review('username5', 1, 5, 'Meh could have been better5');
    management.add_review('username6', 1, 6, 'Meh could have been better6');
    management.add_review('username7', 1, 7, 'Meh could have been better7');
    commit;
end;
