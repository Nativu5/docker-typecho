export DP_Id="Your_DNSPOD_api_ID"

export DP_Key="Your_DNSPOD_api_Token"

~/.acme.sh/acme.sh --issue --dns dns_dp -d yourdomain.com

~/.acme.sh/acme.sh --install-cert -d yourdomain.com \
--key-file       /path/to/dockercompose/nginx/cert/key.pem  \
--fullchain-file /path/to/dockercompose/nginx/cert/cert.pem \
--reloadcmd     "docker restart nginx"
