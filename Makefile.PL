require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile
(
          'PL_FILES' => {},
          'NAME' => 'Net::Proxy',
          'EXE_FILES' => [
                           'script/connect-tunnel',
                           'script/sslh'
                         ],
          'VERSION_FROM' => 'lib/Net/Proxy.pm',
          'PREREQ_PM' => {
                           'Scalar::Util' => 0,
                           'IO::Socket' => 0,
                           'IO::Select' => 0
                         }
        )
;
