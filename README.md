scripts
=======

Miscellaneous scripts written at various times for various purposes.

Some may not work in certain (many?) environments.
If you want to use any of them and they don't work for you, please let me know,
though I can't promise that I will actually fix them.

## File list

* nproc.py

    Like `nproc` from GNU coreutils, but returns the number of physical cores (while `nproc` does not adjust for Hyper-Threading).

* usg-config-export.py

    Exports specified sections of a Ubiquiti Unified Service Gateway config into JSON.

* installdate.sh

    Attempts to determine installation date
    of a Linux, FreeBSD, Mac OS X, or Solaris system.

* motto_clock.sh

    Shows the current time plus a time-themed motto in the style of medieval tower clocks.

* ceval.pl

    Compiles and executes C one-liners with gcc. Usage example: `./ceval.pl 'int a = 5 % 2 == 0 ? 1 : 0; printf("%d\n", a);'`

* maya_timestamp.py

    Converts UNIX timestamp to the Maya calendar date. Usage example: `./maya_timestamp.py $(date +%s)`.

* gost94sums.sh

    Creates GOST94 sums file in format analogous to the usual md5sums or sha1sums (may not work with new OpenSSL versions).

* otpgen.pl

    Generates a PDF or plain text one time pad.

* irclogmailer.sh

    Emails yesterday irssi logs to watchers.

* randomfile

    Picks a random file from given directory.

* sshforget

    Removes a line from SSH known_hosts.

* all2pdf.sh

    gunzips and converts all DVI and PS files in a directory to PDF.

* phabricator-query.py

    Automatically retrieves task data from a Phabricator query
    and displays it in HTML or plain text.

* ocacc.py

    Obsessive-compulsive acronym capitalization checker.
    Checks abbreviation/acronym capitalization style against
    a file that lists correctly capitalized versions one per line.

* vyos-release-notes.py

    Generates release notes from Phabricator. It uses custom fields from the VyOS phabricator instance,
    so it's only really useful for VyOS. You can adapt it to your own project, but you are on your own there. ;)
