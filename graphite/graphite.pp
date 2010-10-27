################################################################################
# This Puppet recipe install Ganglia and Graphite on the same host.
# It is still work in progress. Need to resolve patching the source to 
# support Ganglia RRDs and creating the initial Django admin DB
################################################################################

class graphite::common {

 $build_dir = "/tmp"

 $whisper_url = "http://graphite.wikidot.com/local--files/downloads/whisper-0.9.6.tar.gz"

 $whisper_loc = "$build_dir/whisper.tar.gz"

 $webapp_url = "http://graphite.wikidot.com/local--files/downloads/graphite-web-0.9.6.tar.gz"
  
 $webapp_loc = "$build_dir/graphite-web.tar.gz"

 exec { "download-graphite-whisper":
        path => ["/bin", "/usr/bin", "/usr/sbin", "/sbin"],
        command => "wget -O $whisper_loc $whisper_url",
        creates => "$whisper_loc"
   } 

   exec { "install-whisper":
        path => ["/bin", "/usr/bin", "/usr/sbin"],
        command => "cd $build_dir ; tar -zxvf $whisper_loc ; cd whisper-0.9.6 ; python setup.py install",
        subscribe => Exec[download-graphite-whisper],
        refreshonly => true
   }

  exec { "download-graphite-webapp":
        path => ["/bin", "/usr/bin", "/usr/sbin", "/sbin"],
        command => "wget -O $webapp_loc $webapp_url",
        creates => "$webapp_loc"
   }      

   exec { "install-webapp":
        path => ["/bin", "/usr/bin", "/usr/sbin"],
        command => "cd $build_dir ; tar -zxvf $webapp_loc ; cd graphite-web-0.9.6 ; python setup.py install",
        subscribe => Exec[download-graphite-whisper],
        refreshonly => true
   }


  file { "/opt/graphite/storage":
                owner => $operatingsystem ? {
		  ubuntu => "www-data",
		  centos => "apache"
		}, 
		subscribe => Exec["install-webapp"],
                recurse => inf;
  }


}

#/opt/graphite/webapp/graphite# python manage.py syncdb
#Could not import graphite.local_settings, using defaults!
#Could not import graphite.local_settings, using defaults!

# patch -p0 < ../graphite.diff 

class graphite::centos {

  $apache_user = "apache"

  package { 
        [ python-django, python-simplejson, mod_python, python-memcached, python-sqlite2, rrdtool-python]: ensure => latest;
  }

}

class graphite::ubuntu {

  $apache_user = "www-data"

  package {
        [ python-django, python-simplejson, libapache2-mod-python, python-memcache, python-pysqlite2, python-rrdtool]: ensure => latest;
  }

}


class ganglia::common {

 service {
#        gmond:
#                ensure => running,
 #               enable => true;  

        gmetad:
                ensure => running,
                enable => true;  

  }
}

class ganglia::centos {

 package { 
        [ ganglia-gmond, ganglia-gmond-modules-python, ganglia-gmetad]: ensure => latest;

  }

}

class ganglia::ubuntu {

 package { 
        [ ganglia-monitor, gmetad]: ensure => latest;

  }

}


include graphite::common
include "graphite::$operatingsystem"

include ganglia::common
include "ganglia::$operatingsystem"
