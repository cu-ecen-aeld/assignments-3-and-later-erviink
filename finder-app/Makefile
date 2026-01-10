.PHONY:clean

writer:writer.o
	gcc writer.o -o writer
writer.o:writer.c
	gcc -c writer.c -o writer.o
clean:
	rm -f *.o writer
