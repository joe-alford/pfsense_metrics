# pfSense monitoring

## SNMP

Please see [detailed instructions at medium](https://joealford.medium.com/6c37e82ca89f) - but a rough overview is below.

In essence, we use Prometheus' `snmp_exporter` to expose SNMP data in a format that Prometheus will understand. We then use Grafana's `Alloy` to collect, and forward those metrics up to our cloud hosted Prom/Grafana.

Relevant config can be found in:

- `/etc/alloy/config.alloy` - use this to define the targets
- `/etc/default/alloy` - used to enable other IPs to access to the `Alloy` web console -probably doesn't need changing
- `/etc/snmp_exporter/snmp_exporter` - this defines the SNMP MIBs (including our custom `pfsense` one, as created using the [snmp_exporter generator](https://github.com/prometheus/snmp_exporter/tree/main/generator) (the guide linked above includes a how-to)), and the SNMPv2 community string. This shouldn't need changing once deployed.
- `/etc/systemd/system/syslog_proxy_*.service` - this defines the service that takes inbound pfSense syslogs and transforms them to be acceptable to Loki

### pfSense config

To enable SNMP on pfSense, do the following:

`Services` -> `SNMP`
- Enable [x]
- Set the `Read Community String`
- SNMP modules
    - Mibll [x]
    - Netgraph [x]
    - PF [x]
    - Host Resources [x]
    - UCD [x]
    - Regex [ ]
- Select the relevant interface
- Save

`Firewall` -> `Rules`

Add a new rule to `pass` 161 on the relevant interface

Follow this [guide to generate MIBs for pfsense](https://brendonmatheson.com/2021/02/07/step-by-step-guide-to-connecting-prometheus-to-pfsense-via-snmp.html) (making sure to `git checkout` the `snmp_exporter` version that is in `scripts\provisioners\snmp_exporter.sh), but possibly not needed because of this file? https://gist.github.com/h3po/29e98c4480afdfae6fa9faee2fdb6ea8

### Diagnosing

#### Grafana Alloy

There's a few things here that we can do, assuming that `info` or `debug` is enabled in the `Alloy` config (`/etc/alloy/config.alloy`).
- we can look into the `journalctl` logs - (`journalctl -u alloy.service`)
- we can use a web browser to navigate to the debug page, which is at: `<EC2_instance_IP>:12345`. From there, we can navigate to see the status of different `Components` etc.

#### SNMP Exporter

`jounralctl` (`journalctl -u snmp_exporter.service`) doesn't have logs that are quite as useful as `Alloy`'s, but we do have a nice web interface which we can use to probe SNMP devices to see what happens. This is at `<EC2_instance_IP>:9116`. This will pull the `auth` and `module` fields from `/etc/snmp_exporter/snmp.yml`.

## Syslog

Please be aware, we are hitting these bugs, which will explain some of the odd config...

https://github.com/grafana/alloy/issues/560
https://github.com/grafana/loki/issues/12436

As a result of the above bugs, we can't just send our logs straight from pfSense to `Alloy` - we have to modify the log entries first. To that end, our design is something like this: 
- we start `Alloy` listening on port `n`
- we start a `syslog proxy` listening on port `1n`
- pfSense generates logs, and sends them to the `syslog proxy` on port `1n`
- the `syslog proxy` modifies the log as required, and then forwards onto `Alloy` on port `1n`
- `Alloy` sends up to Grafana Cloud

To make this work nicely, we need to have one `syslog proxy` per pfSense instance (the reason being so we can filter by pfSense instance, and not group all logs together). To this end, we need one service (`config\etc\systemd\system\syslog_proxy_15140.service`) for each pfSense. We can add these on the EC2 instance, rather than changing the image.

For each `syslog proxy`, we will need a corresponding `listener` in `loki.source.syslog` within `config\etc\alloy\config.alloy`. Again, this can be configured on the EC2 instance itself, and not in the image.


### `syslog proxy` config

To add a new `syslog proxy` service is a simple process, and looks like this:

- copy an existing service definition: `sudo cp /etc/systemd/system/syslog_proxy_15140.service /etc/systemd/system/syslog_proxy_15141.service`
- edit the new file to update the `--listen-port` and `--forward-port` (try to keep the convention of `listen-port` having a `1` at the start, and the `forward-port` being the same number, without the leading `1`): `sudo vim /etc/systemd/system/syslog_proxy_15141.service`
- reload the systemd daemon and enable the service: `sudo systemctl daemon-reload && sudo systemctl enable syslog_proxy_15141.service`
- start the service: `sudo systemctl start syslog_proxy_15141.service`
- and then check it's status: `systemctl status syslog_proxy_15141.service
- you can view the service's logs with `sudo journalctl -u syslog_proxy_15141.service`

### Grafana `Alloy` config

Once we've added a new `proxy service` (above), we'll need to update the running `Alloy` config to have a listener, too:

- edit `/etc/alloy/config.alloy` and copy an existing `listener` block, making sure to bind it the port defined in the `syslog proxy` service above. Update the `labels` as required.
- restart the `Alloy` service: `sudo systemctl restart alloy`

### pfSense config

To configure `syslog` on pfSense, do the following:

`Status` -> `System Logs` -> `Settings`

- `Log Message Format`: `syslog`/RFC 5424
- `Remote Logging Options`
    - `Send log messages to remote syslog server` [x]
    - `IP Protocol`: IPv4
    - `Remote log servers`: `<EC2_instance_IP>:<syslog proxy port>`
    - `Remote Syslog Contents`: `Everything` [x]
- Save