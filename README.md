# Gramps Web Demo Script


This is a script used at the Gramps Web Demo Server https://demo.grampsweb.org/.

The Demo Server was installed with the following procedure:

- Install the [Gramps Web DigitalOcean 1-click app](https://www.grampsweb.org/DigitalOcean/)
- Point `demo.grampsweb.org` to the newly created droplet (A record)
- Set `demo.grampsweb.org` as domain name in the 1-click app startup script
- Set up an SSH key
- Copy the reset script to the server: `scp reset.sh demo.grampsweb.org:`
- Add a cron job on the server: `echo "0 */2 * * * /bin/bash /root/reset.sh" | crontab -`