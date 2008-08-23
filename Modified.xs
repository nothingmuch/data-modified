#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#ifdef PERL_MAGIC_uvar

#endif

STATIC void call_hook (pTHX_ SV *sv, SV *cv) {
	dSP;
	SV *rv = newRV_inc(sv);
	sv_2mortal(rv);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(rv);

	PUTBACK;
	call_sv(cv, G_DISCARD);

	FREETMPS;
	LEAVE;
}

STATIC void zap_magic (SV *sv, MAGIC *mg, MAGIC *prevmg) {
	if (prevmg) {
		prevmg->mg_moremagic = mg->mg_moremagic;
	} else {
		if ( !mg->mg_moremagic ) {
			SvMAGICAL_off(sv);
			SvMAGIC_set(sv, NULL);
		} else {
			SvMAGIC_set(sv, mg->mg_moremagic);
		}
	}

	mg->mg_moremagic = NULL;

	SvREFCNT_dec(mg->mg_obj);
	Safefree(mg);
}

STATIC int mg_touched (pTHX_ SV *sv, MAGIC *mg) {
	SV *track = mg->mg_obj;

	switch (SvTYPE(track)) {
		case SVt_PVCV:
			call_hook(aTHX_ sv, track);
			break;
		case SVt_PVAV:
			av_push((AV *)track, newRV_inc(sv));
			break;
		default:
			sv_inc(track);
			break;
	}

	if ( mg->mg_private ) {
		MAGIC *prevmg = NULL;
		MAGIC *nextmg = SvMAGIC(sv);

		while ( nextmg != mg && nextmg->mg_moremagic ) {
			prevmg = nextmg;
			nextmg = nextmg->mg_moremagic;
		}

		zap_magic(sv, mg, prevmg);
    }
}

STATIC MGVTBL vtbl = {
    NULL, /* get */
    mg_touched, /* set */
    NULL, /* len */
    mg_touched, /* clear */
    NULL, /* free */
#if MGf_COPY
    NULL, /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
    NULL, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
    NULL, /* local */
#endif /* MGf_LOCAL */
};

STATIC MAGIC *cast (pTHX_ SV *sv, SV *listener, U16 once) {
    MAGIC *mg = sv_magicext(sv, listener, PERL_MAGIC_ext, &vtbl, NULL, 0 );
    mg->mg_flags |= MGf_REFCOUNTED;
	mg->mg_private = once;
    return mg;
}

STATIC void uncast (pTHX_ SV *sv, SV *listener) {
	MAGIC *prevmg, *mg;

	if (SvTYPE(sv) >= SVt_PVMG) {
		for (prevmg = NULL, mg = SvMAGIC(sv); mg; prevmg = mg, mg = mg->mg_moremagic) {
			if ((mg->mg_type == PERL_MAGIC_ext) && (mg->mg_obj == listener))
				break;
		}

		if (mg)
			zap_magic(sv, mg, prevmg);
	}
}

MODULE = Data::Modified	PACKAGE = Data::Modified
PROTOTYPES: ENABLE

void
track(sv, listener, ...)
	INPUT:
		SV *sv;
		SV *listener;
	PROTOTYPE: $$;$
	CODE:
		if ( !SvROK(listener) )
			croak("listener must be a reference");

		(void)cast(aTHX_ SvROK(sv) ? SvRV(sv) : sv, SvRV(listener), items > 2 ? SvTRUE(ST(2)) : 0 );

void
untrack(sv, listener)
	INPUT:
		SV *sv;
		SV *listener;
	PROTOTYPE: $$
	CODE:
		if ( !SvROK(listener) )
			croak("listener must be a reference");

		(void)uncast(aTHX_ SvROK(sv) ? SvRV(sv) : sv, SvRV(listener));

