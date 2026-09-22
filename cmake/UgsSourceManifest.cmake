# Canonical inventory for sources prepared from the pinned upstream UGS archive.
# This file is included by both project configuration and CMake script mode.
set(UGS_SOURCE_NAMES
  aux.c ran.f
  ug2dh1.f ug2dh2.f ug2dh3.f ug2dh4.f ug2dh5.f ug2dh6.f ug2dh7.f
  ug2dhg.f ug2dhp.f ug3lin.f ug3mrk.f ug3pln.f ug3pmk.f
  ug3trn.f ug3txt.f ug3wrd.f ugb001.f ugb002.f ugb003.f ugb004.f ugb005.f
  ugb006.f ugb007.f ugb008.f ugb009.f ugb010.f ugb011.f ugb012.f ugb013.f
  ugb014.f ugb015.f ugc001.f ugc002.f ugc003.f ugc004.f ugc005.f ugc006.f
  ugc007.f ugclos.f ugcnt1.f ugcnt2.f ugcnt3.f ugcnt4.f ugcntr.f ugcnvf.f
  ugctol.f ugd001.f ugd002.f ugd003.f ugddat.f ugdefl.f ugdsab.f ugdspc.f
  ugdupl.f uge001.f uge003.f ugectl.f ugenab.f ugevnt.f ugf001.f ugf002.f
  ugf003.f ugf004.f ugfont.f ugg001.f ugg002.f ugg003.f ugg004.f ugg005.f
  uginfo.f uginit.f uglgax.f uglgdx.f ugline.f uglnax.f uglndx.f ugmark.f
  ugmctl.f ugmes1.f ugmes2.f ugmes3.f ugmes4.f ugmesh.f ugnucl.f ugoption.f
  ugpfil.f ugpict.f ugplin.f ugpmrk.f ugproj.f ugqct1.f ugqctr.f ugrerr.f
  ugscin.f ugshld.f ugsimp.f ugslct.f ugtext.f ugtran.f ugtrn1.f ugtrn2.f
  ugwdow.f ugwrit.f ugxerr.f ugxhch.f ugxsym.f ugxtxt.f ugz001.f
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

set(UGS_SYSTEM_ROOT_FILES
  UGC00CBK.FOR UGD00CBK.FOR UGDDACBK.FOR UGE00CBK.FOR UGEMSCBK.FOR
  UGERRCBK.FOR UGF00CBK.FOR UGG00CBK.FOR UGMCACBK.FOR UGPOTCBK.FOR
  UGPOTCBK.org UGPOTDCL.FOR
)

set(UGS_SYSTEM_DRIVER_FILES
  UGDDACBK.FOR UGDDXEPS.FOR UGDDXGIN.FOR UGDDXGRN.FOR UGDDXGSD.FOR
  UGDDXGSQ.FOR UGDDXIM3.FOR UGDDXIMX.FOR UGDDXMET.FOR UGDDXPDI.FOR
  UGDDXPDL.FOR UGDDXPDS.FOR UGDDXPDU.FOR UGDDXPRX.FOR UGDDXPSC.FOR
  UGDDXQMS.FOR UGDDXSKB.FOR UGDDXSKC.FOR UGDDXSKD.FOR UGDDXSKE.FOR
  UGDDXSSS.FOR UGDDXTAL.FOR UGDDXTIN.FOR UGDDXTIZ.FOR UGDDXTKA.FOR
  UGDDXTKB.FOR UGDDXTKC.FOR UGDDXTKD.FOR UGDDXTKE.FOR UGDDXTKZ.FOR
  UGDDXTSD.FOR UGDDXTSQ.FOR UGDDXTXA.FOR UGDDXTXB.FOR UGDDXTXC.FOR
  UGDDXUIN.FOR UGDDXUSD.FOR UGDDXUSQ.FOR UGDDXVI2.FOR UGDDXVPF.FOR
  UGDDXVS2.FOR UGDDXXWI.FOR UGDDXXWS.FOR UGIOPARM.FOR
)

set(UGS_COPIED_ASSETS
  drivers/cursor1.bmp
  drivers/cursor2.bmp
  drivers/icon.bmp
)

set(UGS_GENERATED_HEADERS
  drivers/rotated.h
  drivers/defaults.h
)

set(UGS_TEST_ONLY_PREPARED_SOURCES
  drivers/xwindowc_selftest.c
)
