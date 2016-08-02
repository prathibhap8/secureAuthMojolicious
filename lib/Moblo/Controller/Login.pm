package Moblo::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

# Method to check session
sub checkSession {
    my $self = shift;
    my $sessionkey = $self->cookie('session');
    my $session_status = $self->login->checkSessionKey($sessionkey);
    if (!$session_status) {
      #code
      $self->render(json => {status => "notAuthenticated",message=>"Please login to use the service"});  
    }else{
      $self->login->markSessionActivity($sessionkey);
      $self->render(json => {status => "Authenticated",message=>"Please wait while we redirect you to dashboard."});
    }  
}

# Method to route to login form
sub login_form {
    my $self = shift;
}

# Method call on logged in by a user
sub on_user_login {
    my $self = shift;
    my $username = $self->param('username');
    my $password = $self->param('password');
    
    my $sessionkey = $self->cookie('session');
    if(!$self->login->checkSessionKey($sessionkey)) { 
        my $validation = $self->_validation;
        return $self->render(json => {status =>"notAuthenticated", message=>"Either username or password is blank"})
          if $validation->has_error;
        my $user_id = $self->login->validateLogin($username,$password);
        
        if (!$user_id){
          return $self->render(json => {status =>"notAuthenticated",message=>"Authentication Failure. Either User name or password is wrong"});   
        }
        my $sessionKey = $self->login->markLoginActivity($user_id);
        if (!$sessionKey) {
            return $self->render(json => {status => "notAuthenticated",message=>"Unexpected Error. Please contact Administrator."});
        }
        $self->cookie(session => $sessionKey);
        return $self->render(json => {status => "Authenticated",message=>"Please wait while we redirect you to dashboard."});
    }
    else {
        $self->login->markSessionActivity($sessionkey);
        $self->render(json => {status => "Authenticated",message=>"Updated active session, redirecting to Dashboard."});
    }
}

# Method to list the dashboard page
sub listing {
    my $self = shift;
    my $sessionkey = $self->getSessionKey();
    my $session_status = $self->login->checkSessionKey($sessionkey);
    if (!$session_status) {
        $self->render(json => {status => "notAuthenticated",message=>"Please login to use the service"});  
    }
    else {
        my $insertion_details = $self->login->getSessionDBInsertionDetails($sessionkey);
        $self->render(json => {status => 'Authenticated',details => [$insertion_details], validatedDetails => [{index=>"1", validated_val=>"Username"}, {index=>"2", validated_val=>"Password"}, {index=>"3", validated_val=>"Status"}]}); 
    }
}

# Method to logout
sub logout {
    my $self = shift;
    my $sessionkey = $self->cookie('session');
    $self->cookie('session' => '', {expires => 1});
    $self->login->markLogoutActivity($sessionkey);
    return $self->redirect_to('/')
}

# Method to check user exists or not
sub _validation {
    my $self = shift;
    my $validation = $self->validation;
    $validation->required('username');
    $validation->required('password');
    return $validation;
}

# Method to get session key
sub getSessionKey {
    my $self = shift;
    return  $self->cookie('session');
}

1;