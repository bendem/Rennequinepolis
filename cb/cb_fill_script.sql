BEGIN
    cb_thing.add_user('username1','password1','Flohic','Erwan');
    cb_thing.add_user('username2','password2','Demarteau','Benjamin');
    cb_thing.add_user('username3','password3','Kamishin','Ilja');
    cb_thing.add_user('username4','password4','Seel','Oceane');
    cb_thing.add_user('username5','password5','Fink','Jerome');
    cb_thing.add_user('username6','password6','Marley','Bob');
    cb_thing.add_user('username7','password7','Morane','Bob');

    cb_thing.add_review('username1', 1, 1, 'Meh could have been better1')
    cb_thing.add_review('username2', 1, 2, 'Meh could have been better2')
    cb_thing.add_review('username3', 1, 3, 'Meh could have been better3')
    cb_thing.add_review('username4', 1, 4, 'Meh could have been better4')
    cb_thing.add_review('username5', 1, 5, 'Meh could have been better5')
    cb_thing.add_review('username6', 1, 6, 'Meh could have been better6')
    cb_thing.add_review('username7', 1, 7, 'Meh could have been better7')
    commit;
EXCEPTION
  WHEN OTHERS THEN
    raise;
END;
