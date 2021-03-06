#!/bin/sh

# 最好把bin也加到系统路径中去
FNCS_INSTALL=~/code/co-simulation
CPPFLAGS="-I$FNCS_INSTALL/include" #  指定头文件（.h文件）的路径
LDFLAGS="-L$FNCS_INSTALL/lib" # gcc 等编译器会用到的一些优化参数，也可以在里面指定库文件的位置
LIBS="-lfncs -lczmq -lzmq" # 告诉链接器要链接哪些库文件

# locate correct mex program
if test "x$MEX" = x
then
    MEX=`which mex`
fi
MEX=/Applications/MATLAB_R2018a.app/bin/mex 

if $MEX --version > /dev/null 2>&1
then
    echo "$MEX is the pdfTeX tool, not the MATLAB MEX compiler"
    echo "please update your PATH to locate MATLAB's MEX compiler"
    exit 1
fi

if test "x$FNCS_PREFIX" != x
then
    CPPFLAGS="$CPPFLAGS -I$FNCS_PREFIX/include"
    LDFLAGS="$LDFLAGS -L$FNCS_PREFIX/lib"
    LIBS="$LIBS -lfncs"
    echo "FNCS_PREFIX set to $FNCS_PREFIX"
fi
echo "CPPFLAGS=$CPPFLAGS"
echo " LDFLAGS=$LDFLAGS"
echo "    LIBS=$LIBS"

# what suffix does mex add?
rm -f conftest.cpp
cat << EOF > conftest.cpp
#include "mex.h"
void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] )
{
}
EOF

if $MEX conftest.cpp > /dev/null 2>&1
then
    echo "mex test file compiled successfully"
else
    echo "unable to compile test file"
    rm -f conftest.*
    exit 1
fi

EXT=
rm -f conftest.cpp
for result in conftest.*
do
    EXT="${result##*.}"
done
rm -f conftest.*

if test "x$EXT" = x
then
    echo "failed to detect mex object extension"
    exit 1
fi
echo "mex object extension is $EXT"

for cpp in fncs_*.cpp
do
    do_mex=yes
    base="${cpp%.*}"
    if test -f $base.$EXT
    then
        if test $base.$EXT -nt $cpp
        then
            do_mex=no
        fi
    fi
    if test "x$do_mex" = xyes
    then
        echo "MEX $cpp"
        $MEX $CPPFLAGS $LDFLAGS $LIBS $cpp || exit 1
    fi
done

echo "all files up to date"
