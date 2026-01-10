#include <stdio.h>
#include <syslog.h>
#include <string.h>
#include <errno.h>

int main (int argc, char *argv[])
{

openlog(argv[0] , LOG_PID, LOG_USER);
if (argc != 3)
{
// wrong paramter count

printf("Wrong parameters, wanted 2, received %d\n", argc-1);
syslog(LOG_ERR,"Wrong paramters, wanted 2, received %d", argc-1);
closelog();
return 1;
}

FILE *f = fopen(argv[1], "w");

if (f == NULL)
{
printf("File can not be created");
syslog(LOG_ERR, "File can not be created: %s", strerror(errno));
closelog();
return 1;
}

syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);
fprintf(f, "%s", argv[2]);

fclose(f);
closelog();
return 0;
}
