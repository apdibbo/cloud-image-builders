#!/usr/bin/python3

import os
import subprocess
import socket
import json
import xml.etree.ElementTree
import shutil
import pathlib
import requests


source = "/var/ossec/etc/ossec.template"
destination = "/var/ossec/etc/ossec.conf"
extra_config_dir = "/var/ossec/etc/extra/"


def dict_to_xml(tag, d):

    elem = xml.etree.ElementTree.Element(tag)
    for key, val in d.items():
        # create an Element
        # class object
        child = xml.etree.ElementTree.Element(key)
        child.text = str(val)
        elem.append(child)

    return elem


# Open template config file
with open(source) as sourcefile:
    ossec_string = sourcefile.read()

# initialise data structures
labels_conf = {}
logfiles_conf = []
fim_conf = []
sca_conf = []
commands_conf = []
active_responses_conf = []
groups_conf = []
wodles_conf = {}

# Load in any additional config
for extra_config_file in pathlib.Path(extra_config_dir).glob("*.json"):
    print(extra_config_file)
    with open(extra_config_file) as extra_config_json:
        extra_config = json.load(extra_config_json)
    labels_conf.update(extra_config.get("labels", {}))
    wodles_conf.update(extra_config.get("wodles", {}))
    logfiles_conf.extend(extra_config.get("logfiles", []))
    fim_conf.extend(extra_config.get("file_integrity_monitoring", []))
    sca_conf.extend(extra_config.get("security_config_assessments", []))
    commands_conf.extend(extra_config.get("commands", []))
    active_responses_conf.extend(extra_config.get("active_responses", []))
    groups_conf.extend(extra_config.get("groups", []))

ossec_conf = xml.etree.ElementTree.parse(source)
ossec_xml = ossec_conf.getroot()

agent_hostname = socket.getfqdn()

# Check if the host is an OpenStack VM
param = '-w 1 -c 1'
metadata_ip = "169.254.169.254"
response = os.system(f"ping {param} {metadata_ip}")
if response == 0:
    try:
        metadata_url = "http://169.254.169.254/openstack/latest/meta_data.json"
        response = requests.get(metadata_url)
        openstack_metadata = response.json()
        metadata_to_parse = ["uuid", "name", "hostname", "project_id"]
        for vm_attr in metadata_to_parse:
            labels_conf["openstack." + vm_attr] = openstack_metadata[vm_attr]
        agent_hostname = agent_hostname + "-" + openstack_metadata["uuid"]
    except:
        print("not an openstack VM")


if os.path.exists("/etc/ccm.conf"):
    print("Is Quattor Managed")
    # Get aquilon personality from profile
    p = subprocess.Popen(
        ["/usr/sbin/ccm", "/system/personality/name"], bufsize=1, stdout=subprocess.PIPE
    )
    personality = p.communicate()
    # Remove cruft from string
    personality = (
        str(personality[0])
        .replace('b"$ name : ', "")
        .replace("'\\n\\n\"", '"')
        .replace("'", '"')
    )
    # Format as XML and merge into Labels XML - probably a better way of doing this but hayho
    labels_conf["aq.personality"] = personality


# Commands for use with Active Responses
for command_item in commands_conf:
    new_command = dict_to_xml("command", command_item)
    ossec_xml.append(new_command)

# Log Files
for logfile_item in logfiles_conf:
    new_logfile = dict_to_xml("localfile", logfile_item)
    ossec_xml.append(new_logfile)

# Security Configuration Assessments
for sca_item in sca_conf:
    new_sca = dict_to_xml("sca", sca_item)
    ossec_xml.append(new_sca)

# Active Response
for activeresponse_item in active_responses_conf:
    new_activeresponse = dict_to_xml("active-response", activeresponse_item)
    ossec_xml.append(new_activeresponse)

# File Integrity monitoring
for fim_item in fim_conf:
    new_fim = dict_to_xml("syscheck", fim_item)
    ossec_xml.append(new_fim)

# Labels
for key, value in labels_conf.items():
    new_label = xml.etree.ElementTree.SubElement(ossec_xml.find("labels"), "label")
    new_label.text = value
    new_label.attrib["key"] = key
# labels_xml = ossec_xml.find('labels')

# Wodles
for wodle_key, wodle_item in wodles_conf.items():
    new_wodle = dict_to_xml("wodle", wodle_item)
    new_wodle.set("name", wodle_key)
    ossec_xml.append(new_wodle)

# Hostname and Groups setup
client_update = ossec_xml.find("client").find("enrollment")
groups_update = xml.etree.ElementTree.SubElement(client_update, "enrollment")
group_seperator = ","
groups_update.tag = "groups"
groups_update.text = group_seperator.join(groups_conf)
hostname_update = xml.etree.ElementTree.SubElement(client_update, "enrollment")
hostname_update.tag = "agent_name"
hostname_update.text = agent_hostname


ossec_conf.write(destination)
