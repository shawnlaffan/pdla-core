package F77Conf;
# a minimal hardcoded config designed for debian so that we don't need
# ExtUtils::F77 when building PDLA

print "Config   ",__PACKAGE__->config(),"\n";
print "Compiler ",__PACKAGE__->compiler(),"\n";
print "Runtime  ",__PACKAGE__->runtime(),"\n";
print "Trail_   ",__PACKAGE__->trail_() ? "yes" : "no", "\n";
print "Cflags   ",__PACKAGE__->cflags(),"\n";


sub config {
  return 'debian';
}

sub runtime {
  my $libpath = `gfortran -print-libgcc-file-name`;
  $libpath =~ s/libgcc[.]a$//;
  chomp $libpath;
  my $ldflags = '';
  $ldflags .= $ENV{LDFLAGS} if (defined $ENV{LDFLAGS});
  $ldflags .= " -L$libpath -lgcc -lgfortran";
  return($ldflags);
}

sub trail_ {
  return 1;
}

sub compiler {
  return 'gfortran';
}

sub cflags {
  my $fflags = '';
  $fflags = $ENV{FFLAGS} if (defined $ENV{FFLAGS});
  $fflags.=' -fPIC';
  return($fflags);
}

sub testcompiler {
  my ($this) = @_;
    my $file = "/tmp/testf77$$";
    my $ret;
    open(OUT,">$file.f");
    print OUT "      print *, 'Hello World'\n";
    print OUT "      end\n";
    close(OUT);
    print "Compiling the test Fortran program...\n";
    my ($compiler,$cflags) = ($this->compiler,$this->cflags);
    system "$compiler $cflags $file.f -o ${file}_exe";
    print "Executing the test program...\n";
    if (`${file}_exe` ne " Hello World\n") {
       print "Test of Fortran Compiler FAILED. \n";
       print "Do not know how to compile Fortran on your system\n";
       $ret=0;
    }
    else{
       print "Congratulations you seem to have a working f77!\n";
       $ret=1;
    }
    unlink("${file}_exe"); unlink("$file.f"); unlink("$file.o") if -e "$file.o";
    return $ret;
}

1;

