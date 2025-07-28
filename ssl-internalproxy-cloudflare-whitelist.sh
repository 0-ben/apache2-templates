<IfModule mod_ssl.c>
<VirtualHost *:443>
    # proxies :443 requests from cloudflare ip only (needs dns record to be proxied in cloudflare settings).
    # if SRC_COUNTRY_FORBIDDEN header is set to any value, will return a 403
    # required to run create-cf-whitelist.sh beforehand

    ServerName my.host.name
    SSLEngine on

    Include /etc/apache2/conf-available/ip_whitelist.conf

    SSLCertificateFile /path/to/ssl/cert
    SSLCertificateKeyFile /path/to/ssl/privatekey

    ProxyPreserveHost On
    # use ufw or other firewall to block 12345
    ProxyPass / http://127.0.0.1:12345/
    ProxyPassReverse / http://127.0.0.1:12345/
    LogFormat "%h %l %u %t \"%r\" %>s %b \"reF: %{Referer}i\" \"UA: %{User-Agent}i\" \"CFCIP: %{CF-Connecting-IP}i\" \"XFF: %{X-Forwarded-For}i\"" cfcloudflare

    # Optional: Logging
    ErrorLog ${APACHE_LOG_DIR}/custom.dev_error.log
    CustomLog ${APACHE_LOG_DIR}/custom.dev_access.log cfcloudflare
    <IfModule mod_rewrite.c>
        RewriteEngine On

        RewriteCond %{HTTP:SRC_COUNTRY_FORBIDDEN} !^$
        RewriteRule ^ - [F]
    </IfModule>
</VirtualHost>
</IfModule>