package PDLA::Perldl2::Profile::Perldl2;
#
# Created on: Sun 25 Apr 2010 03:09:34 PM
# Last saved: Fri 16 Dec 2011 03:19:27 PM 
#

use Moose;
use namespace::clean -except => [ 'meta' ];

$PDLA::Perldl2::Profile::Perldl2::VERSION = 0.008;

with 'Devel::REPL::Profile';

sub plugins {
   qw(
      CleanErrors
      Commands
      Completion
      CompletionDriver::INC
      CompletionDriver::Keywords
      CompletionDriver::LexEnv
      CompletionDriver::Methods
      DDS
      History
      LexEnv
      MultiLine::PPI
      Packages
      NiceSlice
      PrintControl
      ReadLineHistory
      PDLACommands
   ); # CompletionDriver::Globals
}

sub apply_profile {
   my ($self, $repl) = @_;

   # check for Term::ReadLine::Stub
   if ($repl->term->ReadLine =~ /Stub/) {
      $repl->print("WARNING:\n Term::ReadLine::Stub does not support pdl2 features.\n");
      $repl->print(" Please install either Term::ReadLine::Perl or Term::ReadLine::Gnu.\n");
      $repl->print(" Falling back to perldl in the meantime...\n");
      $repl->print("------------------------------------------\n\n");
      exec 'perldl';
   }

   # add PDLA::Perldl2 for plugin search
   push @{$repl->_plugin_app_ns}, 'PDLA::Perldl2';

   foreach my $plug ($self->plugins) {
      if ($plug =~ 'CompletionDriver::INC') {
         eval 'use File::Next';
         next if $@;
      }
      if ($plug =~ 'CompletionDriver::Keywords') {
         eval 'use B::Keywords';
         next if $@;
      }
      $repl->load_plugin($plug);
   }

   # these plugins don't work on win32
   unless ($^O =~ m/win32/i) {
      $repl->load_plugin('Interrupt');
   }

   # enable Term::ReadLine file expansion by default
   $repl->do_readline_filename_completion(1) if $repl->can('do_readline_filename_completion');

   # do perldl stuff here
   $repl->eval('package main');

   $repl->eval('use PDLA');
   $repl->eval('use PDLA::Config');
   $repl->eval('use PDLA::Dbg');
   $repl->eval('use PDLA::Doc::Perldl');
   $repl->eval('use PDLA::IO::Dumper');
   $repl->eval('use PDLA::IO::FlexRaw');
   $repl->eval('use PDLA::IO::Pic');
   $repl->eval('use PDLA::Image2D');
   $repl->eval('use PDLA::AutoLoader');
   $repl->eval('no strict qw(vars)');

   # declare PERLDL package variables
   # most are not used but they are here if needed
   $repl->eval( q[
      @PERLDL::AUTO = ();                                 # code string/refs to run after user enters a new line
      $PERLDL::ESCAPE = '#';                              # Default shell escape character
      $PERLDL::HISTFILESIZE =  $ENV{PERLREPL_HISTLEN};    # Number of lines to keep in history
      $PERLDL::MULTI  = 1;                                # Enable multi-lines by default
      $PERLDL::NO_EOF = 1;                                # Enable EOF protection by default
      $PERLDL::PAGE   = 0;
      $PERLDL::PAGER  = ((exists $ENV{PAGER}) ? $ENV{PAGER} : 'more');
      $PERLDL::PAGING = 0;
      $PERLDL::PROMPT = "pdl> ";                          # string or code reference
      $PERLDL::PREFIX_RE = qr(^\s*(?:pdl|perldl)>\s*);    # RE for shell prompts
      $PERLDL::TERM = $_REPL->term;
      ] );

   #autoflush STDOUT
   $repl->eval('$|=1;');
   # p command (NOTE: this is not an alias for print)
   $repl->eval('sub p { local $, = " "; print @_,"\n" };');

   # list history command
   $repl->eval('sub l {
      my $n = $#_ > -1 ? shift : 20;
      my @h = $_REPL->term->GetHistory();
      my $min = $#h < $n-1 ? 0 : $#h-$n+1;
      map { printf "%d: %s\n", $_+1, $h[$_] } ($min..$#h);
      #map {print  "$_: $h[$_]\n"} ($min..$#h);
      };');

   # preliminary support for PDLA demos
   $repl->eval( q{
      sub demo {
      local $_ = lc $_[0] ;
      if(/^$/) {
      print <<EOD;
      Use:
      demo pdl         # general demo

      demo 3d          # 3d demo (requires TriD with OpenGL or Mesa)
      demo 3d2         # 3d demo, part 2. (Somewhat memory-intensive)
      demo 3dgal       # the 3D gallery: make cool images with 3-line scripts

      demo pgplot      # PGPLOT graphics output (Req.: PGPLOT)
      demo OOplot      # PGPLOT OO interface    (Req.: PGPLOT)

      demo gnuplot     # Gnuplot graphics (requires PDLA::Graphics::Gnuplot)
      demo prima       # Prima graphics (requires PDLA::Graphics::Prima)

      demo transform   # Coordinate transformations (Req.: PGPLOT)
      demo cartography # Cartographic projections (Req.: PGPLOT)

      demo bad         # Bad-value demo (Req.: bad value support)
      demo bad2        # Bad-values, part 2 (Req.: bad value support and PGPLOT)
EOD
      return;
      } # if: /^$/

      my %demos = (
         'pdl' => 'PDLA::Demos::General', # have to protect pdl as it means something
         '3d' => 'PDLA::Demos::TriD1',
         '3d2' => 'PDLA::Demos::TriD2',
         '3dgal' => 'PDLA::Demos::TriDGallery',
         'pgplot' => 'PDLA::Demos::PGPLOT_demo',
         'ooplot' => 'PDLA::Demos::PGPLOT_OO_demo', # note: lowercase
         'bad' => 'PDLA::Demos::BAD_demo',
         'bad2' => 'PDLA::Demos::BAD2_demo',
         'transform' => 'PDLA::Demos::Transform_demo',
         'cartography' => 'PDLA::Demos::Cartography_demo',
         'gnuplot' => 'PDLA::Demos::Gnuplot_demo',
         'prima' => 'PDLA::Demos::Prima',
      );

      if ( exists $demos{$_} ) {
         require PDLA::Demos::Screen; # Get the routines for screen demos.
         my $name = $demos{$_};
         eval "require $name;"; # see docs on require for need for eval
         $name .= "::run";
         no strict 'refs';
         &{$name}();
      } else {
         print "No such demo!\n";
      }

   } } );

   if ($repl->can('do_print')) {
      $repl->eval('sub do_print { $_REPL->do_print(@_) };');
   }

   if ($repl->can('exit_repl')) {
      $repl->eval('sub quit { $_REPL->exit_repl(1) };');
   } else {
      $repl->eval('sub quit { $_REPL->print("Use Ctrl-D or exit to quit" };');
   }

   $repl->prompt($PERLDL::PROMPT);  # new prompt

   if ( defined $ENV{TERM} and $ENV{TERM} eq 'dumb' ) {
      $repl->print("\n");
      $repl->print("******************************************\n");
      $repl->print("* Warning: TERM type is dumb!            *\n");
      $repl->print("* Limited ReadLine functionality will be *\n");
      $repl->print("* available.  Please unset TERM or use a *\n");
      $repl->print("* different terminal type.               *\n");
      $repl->print("******************************************\n");
      $repl->print("\n");
   }

   $repl->print("Perldl2 Shell v$PDLA::Perldl2::Profile::Perldl2::VERSION
      PDLA comes with ABSOLUTELY NO WARRANTY. For details, see the file
      'COPYING' in the PDLA distribution. This is free software and you
      are welcome to redistribute it under certain conditions, see
      the same file for details.\n");

   $repl->print("Loaded plugins:\n");
   {
      my @plugins = ();
      foreach my $pl ( $repl->_plugin_locator->plugins ) {
         # print names of ones that have been loaded
         my $plug = $pl;
         $plug =~ s/^.*Plugin::/  /;
         push @plugins, $plug if $repl->does($pl);
      }
      # Need smarter display of plugins, fill out the line
      # and list CompletionDrivers under Completion
      $repl->print(join "\n", sort(@plugins));
      $repl->print("\n");
   }

   $repl->print("Type 'help' for online help\n");
   $repl->print("Type Ctrl-D or quit to exit\n");
   $repl->print("Loaded PDLA v$PDLA::VERSION\n");
}

1;

__END__

=head1 NAME

PDLA::Perldl2::Profile::Perldl2 - profile for Perldl2 shell

=head1 SYNOPSIS

    system> re.pl --profile=PDLA::Perldl2::Profile::Perldl2  # unix-ish shell
    system> re    --profile=PDLA::Perldl2::Profile::Perldl2  # win32 CMD shell

    Perldl2 Shell v0.008
          PDLA comes with ABSOLUTELY NO WARRANTY. For details, see the file
          'COPYING' in the PDLA distribution. This is free software and you
          are welcome to redistribute it under certain conditions, see
          the same file for details.
    
    Loaded plugins:
      CleanErrors
      Commands
      Completion
      CompletionDriver::INC
      CompletionDriver::Keywords
      CompletionDriver::LexEnv
      CompletionDriver::Methods
      DDS
      FindVariable
      History
      Interrupt
      LexEnv
      MultiLine::PPI
      NiceSlice
      PDLACommands
      Packages
      PrintControl
      ReadLineHistory
    
    
    Type 'help' for online help
    
    Type Ctrl-D or quit to exit
    
    Loaded PDLA v2.006
    
    pdl> 


=head1 DESCRIPTION

This profile is for development of the new PDLA shell (version 2).
The preferred method to start the new shell is via the C<pdl2>
command.  This documentation is provided for C<Devel::REPL> coders
that may wish to use this profile directly for their development.

=head1 SEE ALSO

C<Devel::REPL>, C<Devel::REPL::Profile>, and C<PDLA::Perldl>.

=head1 AUTHOR

Chris Marshall, C<< <chm at cpan dot org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Christopher Marshall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
