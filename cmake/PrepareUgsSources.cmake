# Prepare and patch UGS sources into a generated tree.
#
# Expected variables (passed via -D):
#   UGS_SOURCE_TREE  - path to upstream source tree (e.g. vendor/ugs/src.2.10e)
#   UGS_GEN_DIR      - output directory for generated sources/assets

if(NOT DEFINED UGS_SOURCE_TREE OR UGS_SOURCE_TREE STREQUAL "")
  message(FATAL_ERROR "UGS_SOURCE_TREE is not set for PrepareUgsSources.cmake")
endif()

if(NOT DEFINED UGS_GEN_DIR OR UGS_GEN_DIR STREQUAL "")
  message(FATAL_ERROR "UGS_GEN_DIR is not set for PrepareUgsSources.cmake")
endif()

if(NOT IS_DIRECTORY "${UGS_SOURCE_TREE}")
  message(FATAL_ERROR "UGS_SOURCE_TREE does not exist or is not a directory: ${UGS_SOURCE_TREE}")
endif()

file(MAKE_DIRECTORY "${UGS_GEN_DIR}")

function(_copy_and_patch input abs_out)
  file(READ "${input}" _content)
  string(REPLACE "UGSYSTEM:" "UGSYSTEM_" _content "${_content}")
  string(REGEX REPLACE "INTEGER\\*2[ ]+CHC" "CHARACTER*2     CHC" _content "${_content}")
  get_filename_component(_name "${input}" NAME)
  if(_name STREQUAL "aux.c")
    if(NOT _content MATCHES "#include <string.h>")
      set(_content "#include <string.h>\n${_content}")
    endif()
  elseif(_name STREQUAL "rotated.c")
    if(NOT _content MATCHES "#include <stdlib.h>")
      set(_content "#include <stdlib.h>\n${_content}")
    endif()
    if(NOT _content MATCHES "#include <string.h>")
      string(REPLACE "#include <stdlib.h>\n" "#include <stdlib.h>\n#include <string.h>\n" _content "${_content}")
    endif()
  endif()
  get_filename_component(_outdir "${abs_out}" DIRECTORY)
  file(MAKE_DIRECTORY "${_outdir}")
  file(WRITE "${abs_out}" "${_content}")
endfunction()

function(_copy_if_exists relpath)
  set(in "${UGS_SOURCE_TREE}/${relpath}")
  set(out "${UGS_GEN_DIR}/${relpath}")
  if(EXISTS "${in}")
    _copy_and_patch("${in}" "${out}")
  else()
    message(STATUS "(skip) missing in upstream: ${relpath}")
  endif()
endfunction()

function(_generate_xwtest_source)
  set(in "${UGS_SOURCE_TREE}/drivers/xwindowc.c")
  set(out "${UGS_GEN_DIR}/drivers/xwindowc_selftest.c")
  if(NOT EXISTS "${in}")
    message(STATUS "(skip) missing in upstream: drivers/xwindowc.c")
    return()
  endif()

  file(READ "${in}" _content)
  string(REPLACE "UGSYSTEM:" "UGSYSTEM_" _content "${_content}")
  string(REGEX REPLACE "INTEGER\\*2[ ]+CHC" "CHARACTER*2     CHC" _content "${_content}")
  string(REPLACE "main ()" "void main ()" _content "${_content}")

  get_filename_component(_outdir "${out}" DIRECTORY)
  file(MAKE_DIRECTORY "${_outdir}")
  file(WRITE "${out}" "${_content}")
endfunction()

function(_copy_ugsystem_files base_subdir)
  foreach(oldfile
    UGC00CBK.FOR UGD00CBK.FOR UGDDACBK.FOR UGE00CBK.FOR UGEMSCBK.FOR UGERRCBK.FOR
    UGF00CBK.FOR UGG00CBK.FOR UGMCACBK.FOR UGPOTCBK.FOR UGPOTCBK.org UGPOTDCL.FOR
  )
    set(src "${UGS_SOURCE_TREE}/${base_subdir}/UGSYSTEM:${oldfile}")
    if(EXISTS "${src}")
      set(dst "${UGS_GEN_DIR}/${base_subdir}/UGSYSTEM_${oldfile}")
      _copy_and_patch("${src}" "${dst}")
    endif()
  endforeach()

  foreach(oldfile
    UGDDACBK.FOR UGDDXEPS.FOR UGDDXGIN.FOR UGDDXGRN.FOR UGDDXGSD.FOR UGDDXGSQ.FOR
    UGDDXIM3.FOR UGDDXIMX.FOR UGDDXMET.FOR UGDDXPDI.FOR UGDDXPDL.FOR UGDDXPDS.FOR
    UGDDXPDU.FOR UGDDXPRX.FOR UGDDXPSC.FOR UGDDXQMS.FOR UGDDXSKB.FOR UGDDXSKC.FOR
    UGDDXSKD.FOR UGDDXSKE.FOR UGDDXSSS.FOR UGDDXTAL.FOR UGDDXTIN.FOR UGDDXTIZ.FOR
    UGDDXTKA.FOR UGDDXTKB.FOR UGDDXTKC.FOR UGDDXTKD.FOR UGDDXTKE.FOR UGDDXTKZ.FOR
    UGDDXTSD.FOR UGDDXTSQ.FOR UGDDXTXA.FOR UGDDXTXB.FOR UGDDXTXC.FOR UGDDXUIN.FOR
    UGDDXUSD.FOR UGDDXUSQ.FOR UGDDXVI2.FOR UGDDXVPF.FOR UGDDXVS2.FOR UGDDXXWI.FOR
    UGDDXXWS.FOR UGIOPARM.FOR
  )
    set(src "${UGS_SOURCE_TREE}/${base_subdir}/UGSYSTEM:${oldfile}")
    if(EXISTS "${src}")
      set(dst "${UGS_GEN_DIR}/${base_subdir}/UGSYSTEM_${oldfile}")
      _copy_and_patch("${src}" "${dst}")
    endif()
  endforeach()
endfunction()

function(_copy_asset_if_exists relpath)
  set(in "${UGS_SOURCE_TREE}/${relpath}")
  set(out "${UGS_GEN_DIR}/${relpath}")
  if(EXISTS "${in}")
    get_filename_component(_outdir "${out}" DIRECTORY)
    file(MAKE_DIRECTORY "${_outdir}")
    file(COPY "${in}" DESTINATION "${_outdir}")
  else()
    message(STATUS "(skip) missing asset in upstream: ${relpath}")
  endif()
endfunction()

set(UGS_SOURCE_NAMES
  aux.c ran.f ug2dhg.f ug2dhp.f ug3lin.f ug3mrk.f ug3pln.f ug3pmk.f
  ug3trn.f ug3txt.f ug3wrd.f ugb001.f ugb002.f ugb003.f ugb004.f ugb005.f
  ugb006.f ugb007.f ugb008.f ugb009.f ugb010.f ugb011.f ugb012.f ugb013.f
  ugb014.f ugb015.f ugc001.f ugc002.f ugc003.f ugc004.f ugc005.f ugc006.f
  ugc007.f ugclos.f ugcnt1.f ugcnt2.f ugcnt3.f ugcnt4.f ugcntr.f ugcnvf.f
  ugctol.f ugd001.f ugd002.f ugd003.f ugddat.f ugdefl.f ugdsab.f ugdspc.f
  ugdupl.f uge001.f uge003.f ugectl.f ugenab.f ugevnt.f ugf001.f ugf002.f
  ugf003.f ugf004.f ugfont.f ugg001.f ugg002.f ugg003.f ugg004.f ugg005.f
  uginfo.f uginit.f uglgax.f uglgdx.f ugline.f uglnax.f uglndx.f ugmark.f
  ugmctl.f  ugmesh.f ugnucl.f ugoption.f ugpfil.f ugpict.f ugplin.f ugpmrk.f
  ugproj.f ugqctr.f ugrerr.f ugscin.f ugshld.f ugsimp.f ugslct.f ugtext.f
  ugtran.f ugwdow.f ugwrit.f ugxerr.f ugxhch.f ugxsym.f ugxtxt.f ugz001.f
  ugz002.f ugz003.f ugz006.f uge002.F ugfrev.F uggetv.F ugopen.F ugz005.F
  bit/btest.c bit/iand.c bit/ibclr.c bit/ibset.c bit/ior.c bit/ishft.c bit/ishftc.c
  drivers/epsf.f drivers/postscr.f drivers/rotated.c
  drivers/xwindow.f drivers/xwindowc.c
  dummies/ugcw01.f dummies/uggd01.f dummies/uggi01.f
  dummies/uggks_dummy.f dummies/uggr01.f dummies/uggs01.f dummies/ugin01.f dummies/ugix01.f
  dummies/ugmt01.f dummies/ugpi01.f dummies/ugpl01.f dummies/ugpm01.f dummies/ugps01.f
  dummies/ugpu01.f dummies/ugpx01.f dummies/ugqm01.f dummies/ugsa01.f dummies/ugsb01.f
  dummies/ugsc01.f dummies/ugsd01.f dummies/ugse01.f dummies/ugsixel_dummy.f dummies/ugsx01.f
  dummies/ugta01.f dummies/ugtd01.f dummies/ugts01.f dummies/ugtx01.f dummies/ugud01.f
  dummies/uguis_dummy.f dummies/ugus01.f dummies/ugux01.f dummies/ugvf01.f dummies/ugvi01.f
  dummies/ugvs01.f dummies/ugwa01.f dummies/ugwb01.f dummies/ugwc01.f dummies/ugwd01.f
  dummies/ugwe01.f dummies/ugwz01.f dummies/ugxa01.f dummies/ugxb01.f dummies/ugxc01.f
  dummies/ugxs01.f dummies/ugzz01.f
)

foreach(src_name IN LISTS UGS_SOURCE_NAMES)
  _copy_if_exists(${src_name})
endforeach()

_copy_ugsystem_files("")
_copy_ugsystem_files("drivers")
_generate_xwtest_source()

_copy_asset_if_exists(drivers/cursor1.bmp)
_copy_asset_if_exists(drivers/cursor2.bmp)
_copy_asset_if_exists(drivers/icon.bmp)

set(_rot_in  "${UGS_SOURCE_TREE}/drivers/rotated.h")
set(_rot_out "${UGS_GEN_DIR}/drivers/rotated.h")
if(NOT EXISTS "${_rot_out}")
  if(EXISTS "${_rot_in}")
    _copy_if_exists(drivers/rotated.h)
  else()
    file(MAKE_DIRECTORY "${UGS_GEN_DIR}/drivers")
    file(WRITE "${_rot_out}" "/* Auto-generated fallback: rotated.h */\n#ifndef UGS_ROTATED_H\n#define UGS_ROTATED_H\n#endif\n")
  endif()
endif()

set(_def_in  "${UGS_SOURCE_TREE}/drivers/defaults.h")
set(_def_out "${UGS_GEN_DIR}/drivers/defaults.h")
if(NOT EXISTS "${_def_out}")
  if(EXISTS "${_def_in}")
    _copy_if_exists(drivers/defaults.h)
  else()
    file(MAKE_DIRECTORY "${UGS_GEN_DIR}/drivers")
    file(WRITE "${_def_out}" "/* Auto-generated fallback: defaults.h */\n#ifndef UGS_DEFAULTS_H\n#define UGS_DEFAULTS_H\n#endif\n")
  endif()
endif()
