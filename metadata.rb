name             'weave'
maintainer       'Flexiant Ltd.'
maintainer_email 'contact@flexiant.com'
license          'Apache v2.0'
description      'Installs/Configures weave'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION')).chomp

source_url       'https://github.com/flexiant/weave'
issues_url       'https://github.com/flexiant/weave/issues'

supports 'ubuntu', '>= 15.04'

depends 'compat_resource'
depends "docker" , '= 1.1.49'