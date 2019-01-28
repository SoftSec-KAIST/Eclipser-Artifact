/*
 * Provide a replacement function for realloc, if ./configure finds
 * that the original realloc() is not portable.
 * See info autoconf, section "Particular Function Checks".
 *
 * Copied and modified from gnulib.
 * Here is the original copyright from realloc:
 */

/*
   realloc() function that is glibc compatible.

   Copyright (C) 1997, 2003-2004, 2006-2007, 2009-2015 Free Software
   Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

   written by Jim Meyering and Bruno Haible	*/

#undef realloc

#include <stddef.h>

void *realloc();

void *
rpl_realloc(void *p, size_t n)
{
	if (n == 0) {
		n = 1;
		free(p);
		p = NULL;
	}

	if (p == NULL) {
		if (n == 0)
			n = 1;
		return malloc(n);
	} else {
		return realloc(p, n);
  }
}
