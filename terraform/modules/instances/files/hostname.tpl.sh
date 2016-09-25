#!/usr/bin/env bash
echo ${hostname} > /etc/hostname
echo "$(hostname -I) ${hostname}" >> /etc/hosts
hostname ${hostname}
