package Moblo::Model::Login;
use Mojo::Base -base;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Data::Dumper;
use Time::HiRes qw( gettimeofday );

 
has 'sqlite';

# Method to check if session key is valid
sub checkSessionKey{
    my ($self, $session_key) = @_;
    my $db = $self->sqlite->db;
    return 0 if (!$session_key);
    my $id = $self->sqlite->db->query('SELECT
                                            sd.userlogin_id
                                        AS
                                            uid
                                        FROM
                                            sessionDetail sd
                                        JOIN
                                            userlogin ul
                                        ON
                                            ul.id = sd.userlogin_id
                                        WHERE
                                            sessionkey = ?
                                        AND
                                            sd.status = 1
                                        AND
                                            ul.status = 1', $session_key)->hash;
    return 0 if (!$id);
    return $id->{uid};
}

# Method to check if user is valid or not
sub validateLogin{
    
    my ($self,$username,$password) = @_;
    my $md5password = md5_hex($password);
    my $id = $self->sqlite->db->query('SELECT
                                            id
                                        AS
                                            user_id
                                        FROM
                                            userlogin
                                        WHERE
                                            user_name = ?
                                        AND
                                            password = ?
                                        AND
                                            status = 1', $username,$md5password)->hash;
    return 0 if (!$id);
    return $id->{user_id};
}

# Method to insert login activity details
sub markLoginActivity{
    my ($self,$user_id) = @_;
    my ($seconds) = gettimeofday;
    my $key_hash = $user_id."kimoti".$seconds;
    my $sessionKey = md5_hex($key_hash);
    my $db = $self->sqlite->db;
    my $sql = ' INSERT
                INTO
                    sessionDetail
                    (logintime,sessionkey,status,userlogin_id,lastactivetime)
                VALUES
                    (?, ?,?,?,?)';
    my $insert_id = $db->query($sql, $seconds, $sessionKey,"1",$user_id,$seconds)->last_insert_id;
    return 0 if(!$insert_id);
    return $sessionKey;
}

# Method to update last activity detail
sub markSessionActivity{
    my ($self,$sessionKey) = @_;
    my ($seconds) = gettimeofday;
    my $db = $self->sqlite->db;
    my $sql = ' UPDATE
                    sessionDetail
                SET
                    lastactivetime = ? 
                WHERE
                    sessionkey = ? 
                AND
                    status = 1';
    my $update_status = $db->query($sql, $seconds, $sessionKey);
    return 0 if(!$update_status);
    return 1;
}

# Method to update logout activity
sub markLogoutActivity{
    my ($self,$sessionKey) = @_;
    my ($seconds) = gettimeofday;
    my $db = $self->sqlite->db;
    my $sql = ' UPDATE
                    sessionDetail
                SET
                    lastactivetime = ? ,
                    status = 0
                WHERE
                    sessionkey = ? 
                AND
                    status = 1';
    my $update_status = $db->query($sql, $seconds, $sessionKey);
    return 0 if(!$update_status);
    return 1;
}

# Method to get listing details for dashboard
sub getSessionDBInsertionDetails{
    my ($self,$sessionKey) = @_;
    my $sql = "SELECT
                    id,
                    datetime(lastactivetime, 'unixepoch', 'localtime') as lastactivetime,
                    datetime(logintime, 'unixepoch', 'localtime') as logintime,
                    sessionKey, status, userlogin_id
                FROM
                    sessionDetail
                WHERE
                    sessionkey = ?
                AND
                    status = 1";
    my $details = $self->sqlite->db->query($sql, $sessionKey)->hash;
    return 0 if(!$details);
    return $details;
}
1;