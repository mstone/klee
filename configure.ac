AC_INIT([[klee]],[[0.1.0]],[klee-dev@keeda.stanford.edu])

AC_CONFIG_AUX_DIR(autoconf/)

AC_CONFIG_SRCDIR(["config.mk.in"])

AC_CANONICAL_TARGET

AM_INIT_AUTOMAKE

AC_CONFIG_FILES([config.mk fake/Makefile])

AC_CONFIG_HEADERS([include/klee/Config/config.h])

AH_TOP([#ifndef KLEE_CONFIG_CONFIG_H
#define KLEE_CONFIG_CONFIG_H])
AH_BOTTOM([#endif])


AC_LANG([C++])

AC_CACHE_CHECK([type of operating system to host on],
               [klee_cv_os_type],
[case $host in
  *-*-linux*)
    host_supports_posix_runtime=yes ;;
  *)
    host_supports_posix_runtime=no ;;
esac])

dnl --with-llvm is a shortcut for setting srcdir and objdir.
AC_ARG_WITH(llvm_config,
  AS_HELP_STRING([--with-llvm-config],
    [Name of the llvm-config binary to use to get libllvm pkgconfig info]),,)

AC_CHECK_PROGS(llvm_config, [${with_llvm_config} llvm-config-2.9 llvm-config-2.8 llvm-config-2.7 llvm-config-2.6 llvm-config], [:])

AC_MSG_CHECKING([${llvm_config} --version])
llvm_version=`${llvm_config} --version`
if test X${llvm_version} = X; then
   AC_MSG_ERROR([unable to find llvm-config, use --with-llvm-config])
fi
AC_MSG_RESULT([$llvm_version])

libllvm_cflags=`${llvm_config} --cflags`
AC_SUBST(libllvm_CPPFLAGS,$libllvm_cflags)

libllvm_libs=`${llvm_config} --libs`
AC_SUBST(libllvm_LDFLAGS,$libllvm_libs)

AC_MSG_CHECKING([llvm version major])
llvm_version_major=`echo "$llvm_version" | cut -f1 -d.`
AC_MSG_RESULT([$llvm_version_major])

AC_MSG_CHECKING([llvm version minor])
llvm_version_minor=`echo "$llvm_version" | cut -f2 -d.`
AC_MSG_RESULT([$llvm_version_minor])

AC_DEFINE_UNQUOTED(LLVM_VERSION_MAJOR, $llvm_version_major, [LLVM major version number])
AC_SUBST(LLVM_VERSION_MAJOR,$llvm_version_major)
AC_DEFINE_UNQUOTED(LLVM_VERSION_MINOR, $llvm_version_minor, [LLVM minor version number])
AC_SUBST(LLVM_VERSION_MINOR,$llvm_version_minor)

AC_CHECK_PROGS(llvmar, [llvm-ar-${llvm_version} llvm-ar], [:])
AC_CHECK_PROGS(llvmas, [llvm-as-${llvm_version} llvm-as], [:])
AC_CHECK_PROGS(llvmranlib, [llvm-ranlib-${llvm_version} llvm-ranlib], [:])


dnl LLVM <= 2.6 requires RTTI.
if test $llvm_version_major -eq 2 -a $llvm_version_minor -le 6 ; then
  requires_rtti=1
else
  requires_rtti=0
fi
AC_SUBST(REQUIRES_RTTI,$requires_rtti)

dnl **************************************************************************
dnl User option to enable uClibc support.

AC_ARG_WITH(uclibc,
  AS_HELP_STRING([--with-uclibc],
    [Enable use of the klee uclibc at the given path]),,)

dnl If uclibc wasn't given, check for a uclibc in the current
dnl directory.
if (test X${with_uclibc} = X && test -d uclibc); then
   with_uclibc=uclibc
fi

AC_MSG_CHECKING([uclibc])
if (test X${with_uclibc} != X); then
   if test ! -d ${with_uclibc}; then
       AC_MSG_ERROR([invalid uclibc directory: ${with_uclibc}])
   fi

   dnl Make the path absolute
   with_uclibc=`cd $with_uclibc 2> /dev/null; pwd`

   AC_MSG_RESULT([$with_uclibc])
else
   AC_MSG_RESULT([no])
fi

AC_DEFINE_UNQUOTED(KLEE_UCLIBC, "$with_uclibc", [Path to KLEE uClibc])
AC_SUBST(KLEE_UCLIBC)

if test X${with_uclibc} != X ; then
  AC_SUBST(ENABLE_UCLIBC,[[1]])
else
  AC_SUBST(ENABLE_UCLIBC,[[0]])
fi

dnl **************************************************************************
dnl User option to enable the POSIX runtime

AC_ARG_ENABLE(posix-runtime,
              AS_HELP_STRING([--enable-posix-runtime],
                             [Enable the POSIX runtime]),
                             ,enableval=default)

AC_MSG_CHECKING([POSIX runtime])
if test ${enableval} = "default" ; then
  if test X${with_uclibc} != X; then
    enableval=$host_supports_posix_runtime
    if test ${enableval} = "yes"; then
      AC_MSG_RESULT([default (enabled)])
    else
      AC_MSG_RESULT([default (disabled, unsupported target)])
    fi
  else
    enableval="no"
    AC_MSG_RESULT([default (disabled, no uclibc)])
  fi
else
  if test ${enableval} = "yes" ; then
    AC_MSG_RESULT([yes])
  else
    AC_MSG_RESULT([no])
  fi
fi

if test ${enableval} = "yes" ; then
  AC_SUBST(ENABLE_POSIX_RUNTIME,[[1]])
else
  AC_SUBST(ENABLE_POSIX_RUNTIME,[[0]])
fi

dnl **************************************************************************
dnl See if we should support __ctype_b_loc externals.

dnl FIXME: Do the proper test if we continue to need this.
case $host in
  *-*-linux*)
    AC_DEFINE_UNQUOTED(HAVE_CTYPE_EXTERNALS, 1, [Does the platform use __ctype_b_loc, etc.])
esac

dnl **************************************************************************
dnl Checks for header files.

AC_LANG_PUSH([C])
AC_CHECK_HEADERS([sys/acl.h])
AC_LANG_POP([C])

AC_CHECK_HEADERS([selinux/selinux.h],
        AC_SUBST(HAVE_SELINUX, 1),
        AC_SUBST(HAVE_SELINUX, 0))

AC_ARG_WITH(stp,
  AS_HELP_STRING([--with-stp],
    [Location of STP installation directory]),,)

if test X$with_stp = X ; then
  AC_SUBST(ENABLE_EXT_STP,[[0]])
else
  stp_root=`cd $with_stp 2> /dev/null; pwd`

  old_CPPFLAGS="$CPPFLAGS"
  CPPFLAGS="$CPPFLAGS -I$stp_root/include"
  AC_CHECK_HEADER(stp/c_interface.h,, [
         AC_MSG_ERROR([Unable to use stp/c_interface.h header])
  ])
  CPPFLAGS="$old_CPPFLAGS"

  AC_CHECK_LIB(stp, vc_setInterfaceFlags,, [
         AC_MSG_ERROR([Unable to link with libstp])
  ], -L$stp_root/lib)

  AC_DEFINE(HAVE_EXT_STP, 1, [Using external STP])
  AC_SUBST(ENABLE_EXT_STP,[[1]])
  AC_SUBST(STP_ROOT,$stp_root)
fi

dnl **************************************************************************
dnl * Create the output files
dnl **************************************************************************

AC_OUTPUT
