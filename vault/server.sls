{% from "vault/map.jinja" import vault with context %}
{%- if vault.self_signed_cert.enabled %}
/usr/local/bin/self-cert-gen.sh:
  file.managed:
    - source: salt://vault/files/cert-gen.sh.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

generate self signed SSL certs:
  cmd.run:
    - name: bash /usr/local/bin/self-cert-gen.sh {{ vault.self_signed_cert.hostname }} {{ vault.self_signed_cert.password }}
    - cwd: /etc/vault
    - require:
      - file: /usr/local/bin/self-cert-gen.sh
{% endif -%}

/etc/vault:
  file.directory:
    - user: root
    - group: root
    - mode: 755

/etc/vault/config:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: /etc/vault

/etc/vault/config/server.hcl:
  file.managed:
    - source: salt://vault/files/server.hcl.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /etc/vault/config
    - watch_in:
      - service: vault

{%- if vault.tls_cert_file_content is defined %}
{%- if vault.tls_cert_file is defined %}
install_tls_cert_file:
  file.managed:
    - name: {{ vault.tls_cert_file }}
    - user: root
    - group: root
    - mode: 600
    - contents_pillar: vault:tls_cert_file_content
    - require:
      - file: /etc/vault
{%- endif %}
{%- endif %}

{%- if vault.tls_key_file_content is defined %}
{%- if vault.tls_key_file is defined %}
install_tls_key_file:
  file.managed:
    - name: {{ vault.tls_key_file }}
    - user: root
    - group: root
    - mode: 600
    - contents_pillar: vault:tls_key_file_content
    - require:
      - file: /etc/vault
{%- endif %}
{%- endif %}

{%- if vault.service.type == 'systemd' %}
/etc/systemd/system/vault.service:
  file.managed:
    - source: salt://vault/files/vault_systemd.service.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require_in:
      - service: vault

{% elif vault.service.type == 'upstart' %}
/etc/init/vault.conf:
  file.managed:
    - source: salt://vault/files/vault_upstart.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - require_in:
      - service: vault
{% endif -%}

vault:
  service.running:
    - enable: True
    - require:
      {%- if vault.self_signed_cert.enabled %}
      - cmd: generate self signed SSL certs
      {% endif %}
      - file: /etc/vault/config/server.hcl
      - cmd: install vault
    - onchanges:
      - cmd: install vault
      - file: /etc/vault/config/server.hcl
      {%- if vault.tls_key_file_content is defined %}
      - file: install_tls_key_file
      {% endif %}
      {%- if vault.tls_cert_file_content is defined %}
      - file: install_tls_cert_file
      {% endif %}

vault-init:
  cmd.run:
    - name: echo 'If this is a fresh install or vault has restarted, please make sure you run vault init and unseal Vault'
