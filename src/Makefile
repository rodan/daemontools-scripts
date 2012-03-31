# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

CC = gcc
LD = gcc

CFLAGS = -Wall -O2
DESTDIR =

BIN_TARGETS =
SBIN_TARGETS = svcinit

TARGET = $(SBIN_TARGETS)

all: $(TARGET)

svcinit: svcinit.o
	$(LD) -o $@ $^ -ldl

install: $(TARGET)
	install -m 0755 -d $(DESTDIR)/sbin
	install -m 0755 $(SBIN_TARGETS) $(DESTDIR)/sbin

clean:
	rm -f $(TARGET)
	rm -f *.o *~ core

