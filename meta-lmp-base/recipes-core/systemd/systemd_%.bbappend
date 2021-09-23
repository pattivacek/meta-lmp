FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

ALTERNATIVE_PRIORITY[resolv-conf] = "300"

DEF_FALLBACK_NTP_SERVERS ?= "time1.google.com time2.google.com time3.google.com time4.google.com time.cloudflare.com"
EXTRA_OEMESON += ' \
	-Dntp-servers="${DEF_FALLBACK_NTP_SERVERS}" \
'

SRC_URI:append = " \
	file://0001-cgroup-Simplify-cg_get_path_and_check.patch \
	file://0002-core-Make-user-instance-aware-of-delegated-cgroup-co.patch \
	file://0003-Revert-Silence-cgroups-v1-read-only-filesystem-warni.patch \
	file://0001-tmpfiles-tmp.conf-reduce-cleanup-age-to-half.patch \
	file://systemd-networkd-wait-online.service.in-use-any-by-d.patch \
	file://systemd-timesyncd-update.service \
"

# /var in lmp is expected to be rw, so drop volatile-binds service files
RDEPENDS:${PN}:remove = "volatile-binds"

do_install:append() {
	# prefer nonarch_libdir instead of sysconfdir as this is a core configuration file
	mv ${D}${sysconfdir}/tmpfiles.d/00-create-volatile.conf ${D}${nonarch_libdir}/tmpfiles.d/00-create-volatile.conf
	if [ ${@ oe.types.boolean('${VOLATILE_LOG_DIR}') } = True ]; then
		sed -i '/^d \/var\/log /d' ${D}${nonarch_libdir}/tmpfiles.d/var.conf
		echo 'L+ /var/log - - - - /var/volatile/log' >> ${D}${nonarch_libdir}/tmpfiles.d/00-create-volatile.conf
	else
		# Make sure /var/log is not a link to volatile (e.g. after system updates)
		sed -i '/\[Service\]/aExecStartPre=-/bin/rm -f /var/log' ${D}${systemd_system_unitdir}/systemd-journal-flush.service
	fi

	# Workaround for https://github.com/systemd/systemd/issues/11329
	install -m 0644 ${WORKDIR}/systemd-timesyncd-update.service ${D}${systemd_system_unitdir}
	ln -sf ../systemd-timesyncd-update.service ${D}${systemd_system_unitdir}/sysinit.target.wants/systemd-timesyncd-update.service
}
