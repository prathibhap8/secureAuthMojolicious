package Moblo;
use Mojo::Base 'Mojolicious';
use Moblo::Model::Login;
use Mojo::SQLite;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  $self->defaults(layout => 'base');
  
  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  my $sql = Mojo::SQLite->new('sqlite:obruman.db');
  $self->helper(sqlite => sub { state $sql = Mojo::SQLite->new('sqlite:obruman.db')});
  $self->helper(login => sub { state $login = Moblo::Model::Login->new(sqlite => shift->sqlite) });

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->name('login_form')->to('login#login_form');
  $r->post('/')->name('do_login')->to('login#on_user_login');
  $r->get('/checkSession')->to('login#checkSession');
  $r->get('/listing')->to('login#listing');
  $r->get('/logout')->to('login#logout');
}

1;
