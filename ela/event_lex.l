%{
/*
 * Tokenizer for event catalog
 *
 * Copyright (C) International Business Machines Corp., 2009
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#define CATALOGS_IMPLEMENTATION
#include "catalogs.h"
#include "ev.tab.h"
#include <string.h>
#include <errno.h>
#include <assert.h>
#include <limits.h>

extern EventCtlgParser event_ctlg_parser;
static EventCtlgParser *pc = &event_ctlg_parser;

%}

%option noyywrap

%%
action		{ return KW_ACTION; }
class		{ return KW_CLASS; }
copy		{ return KW_COPY; }
description	{ return KW_DESCRIPTION; }
devspec		{ return KW_DEVSPEC; }
exception	{ return KW_EXCEPTION; }
file		{ return KW_FILE; }
filter		{ return KW_FILTER; }
message		{ return KW_MESSAGE; }
priority	{ return KW_PRIORITY; }
refcode		{ return KW_REFCODE; }
regex		{ return KW_REGEX; }
sl_severity	{ return KW_SL_SEVERITY; }
subsystem	{ return KW_SUBSYSTEM; }
type		{ return KW_TYPE; }

[_A-Za-z][A-Za-z0-9_]* {
	char *name;
	if (! (name = strdup((const char*)yytext)) ) {
		perror("strdup");
		return ERRTOK;
	}
	evlval.sval = name;
	return TK_NAME;
}

\"	{
	char *s = pc->get_string(1);
	if (!s)
		return ERRTOK;
	evlval.sval = s;
	return TK_STRING;
}

\{\{	{
	char *s = pc->get_text_block();
	if (!s)
		return ERRTOK;
	evlval.sval = s;
	return TK_TEXTBLOCK;
}

[ \t\r]	;	/* Skip white space. */

\n	{ pc->lineno++; }

"/*"	{
	if (pc->skip_comment() < 0)
		return ERRTOK;
}

.	{ return yytext[0]; 	/* Pass through any other characters. */ }
%%

/* unput is a macro, but we need a function pointer. */
static void
unput_func(int c)
{
	unput(c);
}

void
EventCtlgParser::init_lex(void)
{
	YY_FLUSH_BUFFER;
	yyrestart(file);
	lineno = 1;
	p_input = yyinput;
	p_unput = unput_func;
}
