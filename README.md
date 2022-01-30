# dbi-DctmApi-gawk

DctmAPI is a gawk's extension that allows to connect and send API commands to Documentum repositories.

## Description

DctmAPI lets gawk scripts connect to Documentum repositories and send it API commands through the dmAPI interface's dmAPISet, dmAPIGet, and dmAPIExec functions.
DctmAPI is actually composed of 2 files: dctm.c, the C interface to libdmcl, and DctmAPI.awk high-level awk functions such as dmConnect(), dmExecute(), dmSelect()/dmNext(), dmDisconnect() that use the interface. Only DctmAPI.awk needs load the interface, gawk scripts don't.
The standard gawk executable must be recompiled and relinked with the interface; it can then be renamed to dmgawk to differentiate it from gawk.
gawk scripts import DctmAPI.awk to access the high-level functions and the ones from the interface; as such, the becomes a Documentum clients.

## Getting Started

### Dependencies

DctmAPI has been written and tested under several versions of Ubuntu linux.
It currently extends gawk v5.1.0 but should do so for any version of gawk >= v4.1 where the dynamic extension interface is available.
It needs Documentum's C interface dmapp.h and the riun-time library libdmcl.so; both are included with the content server.
To compile gawk and the extension, the gcc compiler and its tools, e.g. make, are required.

### Installing

Most of the following steps can be done as a non-privileged used, e.g. dmadmin.

#### As dmadmin, create a working directory and move there
```
mkdir ~/dmgawk; cd ~/dmgawk
```

#### Download the code from git
```
get clone https://github.com/dbiservices/dbi-DctmApi-gawk
```
Although the gawk that is extended is fairly recent, v5.1.0, you may want to work with the latest available gawk. In such a case, get the gawk source files for a recent version, e.g. 5.1.1:
```
wget https://ftp.gnu.org/gnu/gawk/gawk-5.1.0.tar.gz
```
and expand the tarball:
```
tar xvf gawk-5.1.0.tar.gz
```
The important directories are ./gawk-x.x.x (for the recompiled gawk executable), ./gawk-x.x.x/extension (for the Documentum interface dmapp.h and the extension interface dctm.c), and ./gawk-x.x.x/extension/.libs (for the compiled extension dctm.so). Copy the files dmapp.h and dctm.c into the directory ./gawk-x.x.x/extension of the new gawk's subtree.

#### get the aforementioned Documentum files
dmapp.h and libdmcl.so are both included in the project as their distribution is allowed by OpenText. In the highly unlikely case that they are updated in some future release, they can by found in the content server's installation subtree; in v16.4 content server, the former is located in the unsupported directory, e.g. .../product/16.4/unsupported/... and the latter in .../product/16.4/bin.
The run-time library libdmcl.so is currently in the root directory of the project but it can be moved anywhere provided that its path is appended to $LD_LIBRARY_PATH.

#### Compile the extension
```
cd ~/dmgawk/gawk-5.1.0
./configure
make
cd extension
./configure
make
cd .libs
gcc -o dctm.so -shared dctm.o /home/dmadmin/dmgawk/libdmcl.so
```

The new gawk executable is still in gawk-5.1.0. To install it system-wide, generally in /usr/bin, execute the following command as root:
```
cd ~/dmgawk/gawk-5.1.0
make install
```
#### Setting up the environment

The following environment variables must be set in order to access the run-time library libdmcl.so, the interface's shared library dctm.so, the newly compiled gawk and the gawk interface script DctmAPI.awk:
```
export LD_LIBRARY_PATH=/home/dmadmin/dmgawk/gawk-5.1.0:$LD_LIBRARY_PATH
export PATH=/home/dmadmin/dmgawk/gawk-5.1.0:$PATH
export AWKPATH=/home/dmadmin/dmgawk/gawk-5.1.0:$AWKPATH
export AWKLIBPATH=/home/dmadmin/dmgawk/gawk-5.1.0/extension/.libs:$AWKLIBPATH
```

### Executing program

A test program, tdctm.awk, is provided in gawk-5.1.0 to show how to use the ODBC extension. To use it:
```
cd extension
../gawk -f ./todbc.awk
```

## Author

Cesare Cervini, cesare.cervini at dbi-services.com

## Version History

* 0.1
    * Initial Release

## License

This project is free to use, do what you want with it. I hope that it will be useful. Remarks and suggestions are welcome.

## See also

[odbc-gawk, a gawk extension to access databases through ODBC](https://github.com/dbiservices/dbi-odbc-gawk "dbi-odbc-gawk")

More extensions to come. Some of them have already been presented in [dbi-services' blog page](https://blog.dbi-services.com/ "blogs dbi-services")

## Acknowledgments

The fathers of the awk language Alfred V. Aho, Brian W. Kernighan, and Peter J. Weinberger for their incredibly smart and elegant creation.
All the gawk contributors, and especially Arnold D. Robbins, for their outstanding work on the gawk interpreter and the excellent book "GAWK: Effective AWK Programming".


