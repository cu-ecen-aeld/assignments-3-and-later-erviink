.PHONY: all clean

CC ?= $(CROSS_COMPILE)gcc
CFLAGS ?= -g -Wall
LDFLAGS ?=

all:writer
writer:writer.o
	$(CC) $(LDFLAGS) writer.o -o writer
writer.o:writer.c
	$(CC) $(CFLAGS) -c writer.c -o writer.o
clean:
	rm -f *.o writer
